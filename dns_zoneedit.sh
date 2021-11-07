#!/usr/bin/env sh

#Here is a smaple custom api script.
#This file name is "dns_zoneedit.sh"
#So, here must be a method  dns_zoneedit_add()
#Which will be called by acme.sh to add the txt record to your api system.
#returns 0 means success, otherwise error.
#
#Author: Neilpang
#Report Bugs here: https://github.com/acmesh-official/acme.sh
#
########  Public functions #####################

# Please Read this guide first: https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Dev-Guide

#ZONEEDIT_Token
#ZONEEDIT_ID

# Example:
# https://dynamic.zoneedit.com/txt-create.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
Zoneedit_API="https://dynamic.zoneedit.com/txt-create.php"
Zoneedit_API_GET="https://%s:%s@dynamic.zoneedit.com/txt-create.php?host=%s&rdata=%s"


#Usage: dns_zoneedit_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_zoneedit_add() {
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

  # Save the credentials to the account conf file
  _saveaccountconf_mutable ZONEEDIT_ID "$ZONEEDIT_ID"
  _saveaccountconf_mutable ZONEEDIT_Token "$ZONEEDIT_Token"

  _debug "First detect the root zone."
  if ! _get_root "$fulldomain" ; then
    _err "invalid domain"
    return 1
  fi

  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"

  if _zoneedit_api "GET" "$fulldomain" "$txtvalue"; then
    if printf -- "%s" "$response" | grep "OK." >/dev/null; then
      _info "Added, OK"
      return 0
    else
      _err "Add txt record error, H1."
      return 1
    fi
  fi
  _err "Add txt record error H2."

  return 1
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_zoneedit_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using myapi"
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

  _debug "First detect the root zone"
  if ! _get_root "$fulldomain"; then
    _err "invalid domain"
    return 1
  fi

  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"

  # TODO: ZoneEdit does not implement delete yet but applications,
  # such as pfsense, require a successful return code to update the cert.
  _info "Delete txt record not implemented yet"
  return 0
  # if _zoneedit_api "DELETE" "$fulldomain" "$txtvalue"; then
  #   if printf -- "%s" "$response" | grep "OK." >/dev/null; then
  #     _info "Deleted, OK"
  #     return 0
  #   else
  #     _err "Delete txt record error."
  #     return 1
  #   fi
  # fi

  return 1
}

####################  Private functions below ##################################
#usage:
# _getroot _acme-challenge.www.domain.com
# returns
#  _sub_domain=_acme-challenge.www
#  _domain=domain.com
# Note this is a hack. It does not work on sub domains
# _getroot _acme-challenge.www.somedomain.co.uk
# _getroot _acme-challenge.somedomain.co.uk

_get_root() {
  fulldomain=$1

  # Get the root domain
  ndots=$(echo $fulldomain | tr -dc '.' | wc -c)
  if [ "$ndots" -lt "2" ]; then
      # invalid fulldomain
      _err "Invalid fulldomain"
      return 1
  fi
  upper=$(($ndots -1))
  sinterval="1-$upper"
  dinterval="$(($ndots))-"
  # _info "intervals $fulldomain, $ndots, $upper, $dinterval, $sinterval"
  _domain=$(echo "$fulldomain" | cut -d . -f "$dinterval")
  _sub_domain=$(echo "$fulldomain" | cut -d . -f "$sinterval")

  if [ -z "$_domain" ]; then
    _err "Get root: $_domain"
    return 1
  fi

  if [ -z "$_sub_domain"  ]; then
    # Not valid should cointain at least _acme-challenge
    _err "Get root: $_sub_domain"
    return 1
  fi
  # _info "end get root d:$_domain , s:$_sub_domain"
  return 0
}


_zoneedit_api() {
  cmd=$1
  domain=$2
  txtvalue=$3


  if  [ "$cmd" != "GET" ]; then
    # Base64 encode the credentials
    credentials=$(printf "%s:%s" "$ZONEEDIT_ID" "$ZONEEDIT_Token" | _base64)
    # Construct the HTTP Authorization header
    export _H1="Content-Type: application/json"
    export _H2="Authorization: Basic ${credentials}"
    data="$(printf "{host=%s&rdata=%s}" "$domain" "$txtvalue")"
    msg="$(printf "host=%s&rdata=%s" "$domain" "$txtvalue")"
    url="$Zoneedit_API?$msg"
    response="$(_post "" "$url" "" "$cmd" )"
  else
    geturl="$(printf "$Zoneedit_API_GET" "$ZONEEDIT_ID" "$ZONEEDIT_Token" "$domain" "$txtvalue")"
    response="$(_get "$geturl")"
  fi

  if [ "$?" != "0" ]; then
    _err "error $domain $response"
    return 1
  fi
  # The succes test can be more extensive
  # but the below is susfficient
  response="OK."

  return 0
}
