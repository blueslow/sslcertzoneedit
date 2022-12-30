#!/usr/bin/env sh

# https://github.com/blueslow/sslcertzoneedit

# Only need to export the credentials once, acme.sh will save for automatic renewal.
# export ZONEEDIT_ID="Your id"
# export ZONEEDIT_Token="Your token"
# acme.sh --issue --dns dns_zoneedit -d example.com -d www.example.com

# Applications, such as pfsense, require a successful return code to update the cert.

# Notes/To Do (!remove me before merge!)
# * shellcheck & shfmt
# * non-infinite loop
# * Show method used (CREATE/DELETE) in log
# * Credentials not actually hidden???
# * Logging cleanup
# * Conformance against dns_cf.sh (and whatever else the WIKI calls for integration)
# * POSIX
# * Test
#   - dom.tld
#   - sub.dom.tld
#   - dom.tld dom2.tld
#   - dom.tld sub.dom.tld
#   - dom.tld *.dom.tld (wildcard domain)
#   - sub.dom.tld *.sub.dom.tld (wildcard domain) --> Works.
#   - docker
# * https://github.com/acmesh-official/acme.sh/issues/1261
# * https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode
# * https://github.com/acmesh-official/acme.sh/wiki/Code-of-conduct
#
# https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Dev-Guide
#
# Please take care that the rm function and add function are called in 2 different isolated subshells. So, you can not pass any env vars from the add function to the rm function. You must re-do all the preparations of the add function here too.

########  Public functions #####################

# Usage: dns_zoneedit_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_zoneedit_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Zonedit"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  # Load the credentials from the account conf file
  ZONEEDIT_ID="${ZONEEDIT_ID:-$(_readaccountconf_mutable ZONEEDIT_ID)}"
  ZONEEDIT_Token="${ZONEEDIT_Token:-$(_readaccountconf_mutable ZONEEDIT_Token)}"
  if [ -z "$ZONEEDIT_ID" ] || [ -z "$ZONEEDIT_Token" ]; then
    ZONEEDIT_ID=""
    ZONEEDIT_Token=""
    _err "Please specify ZONEEDIT_ID and _Token."
    _err "Please export as ZONEEDIT_ID and ZONEEDIT_Token then try again."
    return 1
  fi

  # Save the credentials to the account conf file
  _saveaccountconf_mutable ZONEEDIT_ID "$ZONEEDIT_ID"
  _saveaccountconf_mutable ZONEEDIT_Token "$ZONEEDIT_Token"

  if _zoneedit_api "CREATE" "$fulldomain" "$txtvalue"; then
    _info "Added, OK"
    return 0
  else
    _err "Add txt record error."
    return 1
  fi
}

# Usage: dns_zoneedit_rm   fulldomain   txtvalue
dns_zoneedit_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Zoneedit"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  # Load the credentials from the account conf file
  ZONEEDIT_ID="${ZONEEDIT_ID:-$(_readaccountconf_mutable ZONEEDIT_ID)}"
  ZONEEDIT_Token="${ZONEEDIT_Token:-$(_readaccountconf_mutable ZONEEDIT_Token)}"
  if [ -z "$ZONEEDIT_ID" ] || [ -z "$ZONEEDIT_Token" ]; then
    ZONEEDIT_ID=""
    ZONEEDIT_Token=""
    _err "Please specify ZONEEDIT_ID and _Token."
    _err "Please export as ZONEEDIT_ID and ZONEEDIT_Token then try again."
    return 1
  fi

  if _zoneedit_api "DELETE" "$fulldomain" "$txtvalue"; then
    _info "Deleted, OK"
    return 0
  else
    _err "Delete txt record error."
    return 1
  fi
}

####################  Private functions below ##################################

#Usage: _zoneedit_api   <CREATE|DELETE>   fulldomain   txtvalue
_zoneedit_api() {
  cmd=$1
  fulldomain=$2
  txtvalue=$3

  # Construct basic authorization header
  credentials=$(printf "%s:%s" "$ZONEEDIT_ID" "$ZONEEDIT_Token" | _base64)
  export _H1="Authorization: Basic ${credentials}"

  # Generate request URL
  case "$cmd" in
  "CREATE")
    # https://dynamic.zoneedit.com/txt-create.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
    geturl="https://dynamic.zoneedit.com/txt-create.php?host=${fulldomain}&rdata=${txtvalue}"
    ;;
  "DELETE")
    # https://dynamic.zoneedit.com/txt-delete.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
    geturl="https://dynamic.zoneedit.com/txt-delete.php?host=${fulldomain}&rdata=${txtvalue}"
    ze_sleep=2
    ;;
  *)
    _err "Unknown parameter : $cmd"
    return 1
    ;;
  esac

  # Execute request
  i=3 # sub-opt
  while [ $i -gt 0 ]; do
    # if i fail, msg

    if ! response=$(_get "$geturl"); then
      _err "_get() failed ($response)"
      return 1
    fi
    _debug2 response "$response"
    if _contains "$response" "SUCCESS CODE=\"200\""; then
      # Sleep (when needed) to work around a Zonedit API bug
      # https://forum.zoneedit.com/threads/automating-changes-of-txt-records-in-dns.7394/page-2#post-23855
      if [ "$ze_sleep" ]; then _sleep "$ze_sleep"; fi
      return 0
    elif _contains "$response" "ERROR" && _contains "$response" "TEXT=\"Minimum"; then
      ze_ratelimit=$(echo "$response" | sed 's/.*Minimum \([0-9]\+\) seconds.*/\1/')
      _info "Zoneedit responded with a rate limit of $ze_ratelimit seconds."
      _sleep "$ze_ratelimit"
    else
      # INCOMPLETE
      _err "$response"
      _err "Unknown response, API change? Will re-try after 10 seconds."
      _sleep 10
    fi
    i=$(_math "$i" - 1)
  done
  return 1
}
