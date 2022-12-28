#!/usr/bin/env sh

# https://github.com/blueslow/sslcertzoneedit

# Only need to export the credentials once, acme.sh will save for automatic renewal.
# export ZONEEDIT_ID="Your id"
# export ZONEEDIT_Token="Your token"
# acme.sh --issue --dns dns_zoneedit -d example.com -d www.example.com

# ZoneEdit HTTP API
# https://dynamic.zoneedit.com/txt-create.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
# https://dynamic.zoneedit.com/txt-delete.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
Zoneedit_API_Create="https://dynamic.zoneedit.com/txt-create.php?host=%s&rdata=%s"
Zoneedit_API_Delete="https://dynamic.zoneedit.com/txt-delete.php?host=%s&rdata=%s"

# Applications, such as pfsense, require a successful return code to update the cert.

# Notes/To Do (!remove me before merge!)
# * _get_root() is not needed to work with ZoneEdit's API, so it can probably be removed.
# * Fix wildcard timeout, min 10 seconds between same-name TXT record creation OR deletion (well it only takes one request to delete both, haven't got far enough to see what acme.sh does at that stage)
# * Show method used (CREATE/DELETE) in log
# * Credentials not actually hidden???
# * Logging cleanup
# * Test
#   - dom.tld
#   - sub.dom.tld
#   - dom.tld dom2.tld
#   - dom.tld sub.dom.tld
#   - dom.tld *.dom.tld (wildcard domain)
#   - sub.dom.tld *.sub.dom.tld (wildcard domain)
# * https://github.com/acmesh-official/acme.sh/issues/1261
# * https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode
#
# https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Dev-Guide
#
# Please take care that the rm function and add function are called in 2 different isolated subshells. So, you can not pass any env vars from the add function to the rm function. You must re-do all the preparations of the add function here too.

########  Public functions #####################

#Usage: dns_zoneedit_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_zoneedit_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Zonedit"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  # Load the credentials from the account conf file
  ZONEEDIT_ID="${ZONEEDIT_ID:-$(_readaccountconf_mutable ZONEEDIT_ID)}"
  ZONEEDIT_Token="${ZONEEDIT_Token:-$(_readaccountconf_mutable ZONEEDIT_Token)}"
  if [ -z "$ZONEEDIT_ID" ] ||
     [ -z "$ZONEEDIT_Token" ] ; then
    ZONEEDIT_ID=""
    ZONEEDIT_Token=""
    _err "Please specify ZONEEDIT_ID and _Token ."
    _err "Please export as ZONEEDIT_ID and ZONEEDIT_Token then try again."
    return 1
  fi

  # Save the credentials to the account conf file
  _saveaccountconf_mutable ZONEEDIT_ID "$ZONEEDIT_ID"
  _saveaccountconf_mutable ZONEEDIT_Token "$ZONEEDIT_Token"

  if _zoneedit_api "CREATE" "$fulldomain" "$txtvalue"; then
    if printf -- "%s" "$response" | grep "OK." >/dev/null; then
      _info "Added, OK"
      return 0
    else
      _err "Add txt record error."
      return 1
    fi
  fi
  _err "Add txt record error."
  return 1

}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_zoneedit_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Zoneedit"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  # Load the credentials from the account conf file
  ZONEEDIT_ID="${ZONEEDIT_ID:-$(_readaccountconf_mutable ZONEEDIT_ID)}"
  ZONEEDIT_Token="${ZONEEDIT_Token:-$(_readaccountconf_mutable ZONEEDIT_Token)}"
  if [ -z "$ZONEEDIT_ID" ] ||
     [ -z "$ZONEEDIT_Token" ] ; then
    ZONEEDIT_ID=""
    ZONEEDIT_Token=""
    _err "Please specify ZONEEDIT_ID and _Token ."
    _err "Please export as ZONEEDIT_ID and ZONEEDIT_Token then try again."
    return 1
  fi

  if _zoneedit_api "DELETE" "$fulldomain" "$txtvalue"; then
     if printf -- "%s" "$response" | grep "OK." >/dev/null; then
       _info "Deleted, OK"
       return 0
     else
       _err "Delete txt record error."
       return 1
     fi
   fi
  return 1
  
}

####################  Private functions below ##################################

#Usage: _zoneedit_api <CREATE|DELETE> <full domain> <rdata>
_zoneedit_api() {
  cmd=$1		# CREATE | DELETE
  domain=$2
  txtvalue=$3

  # Base64 encode the credentials
  credentials=$(printf "%s:%s" "$ZONEEDIT_ID" "$ZONEEDIT_Token" | _base64)
  # Construct the HTTP Authorization header
  export _H1="Authorization: Basic ${credentials}"

  # Generate request URL
  case "$cmd" in
  "CREATE")
    geturl="$(printf "$Zoneedit_API_Create" "$domain" "$txtvalue")"
	;;
  "DELETE")
    geturl="$(printf "$Zoneedit_API_Delete" "$domain" "$txtvalue")"
	;;
  *)
    _err "Unknown parameter : $cmd"
    return 1
    ;;
  esac

  # Execute the request
  response="$(_get "$geturl")"

  # Error checking
  if [ "$?" != "0" ]; then
    _err "error $domain $response"
    return 1
  fi
  if [ "${response%%TEXT*}" != '<SUCCESS CODE="200" ' ]; then
    _err "error $domain $cmd $response"
    return 1
  fi
  # The succes test can be more extensive
  # but the below is sufficient
  response="OK."

  return 0
}
