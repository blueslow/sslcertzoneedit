# sslcertzoneedit

Plugin to create and automatically update let's encrypt ssl certificates via [zoneedit](https://www.zoneedit.com/) dns, acme.sh script and optionally in pfsense.

Prerequisites the [acme.sh](https://github.com/acmesh-official/acme.sh) script or the pfsense acme package.

This is built on information given in the zoneedit forum by Brad C. I qoute
>We've added a DYN endpoint for creating TXT records which can be used to validate letsencrypt certificates.
>The credentials to use are the same as for DYN updates. An example of the parameters that need to be passed:
>```
>https://dynamic.zoneedit.com/txt-create.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
>```
>[Zoneedit forum](https://forum.zoneedit.com/index.php?threads/automating-changes-of-txt-records-in-dns.7394/post-19772)

There are two different installation methods one for an ordinray bash / sh installaiotn and one into [pfsense](https://www.pfsense.org/download/)

## Installation
Install [acme.sh](https://github.com/acmesh-official/acme.sh)

Place the dns_zoneedit.sh file in the .../acme/dnsapi/ folder.
Give execution rights to the dns_zoneedit.sh file, e.g.
```
chmod +x .../acme/dnsapi/dns_zoneeidt.sh
```

### Usage:
First read [How to use DNS AP](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

Before first execution define the following in sh (or bash):
```
export ZONEEDIT_ID="your id"
export ZONEEDIT_Token="Your token"
```
Where ZONEEDIT_ID is your zone edit ID and ZONEEDIT_Token is the same token as for dynamic IP dns update at [zoneedit](https://www.zoneedit.com/).
Then:
```
acme.sh --issue --dns dns_zoneedit -d example.com -d www.example.com
```

## Pfsense installation
Install the acme package. Then place the Place the dns_zoneedit.sh file in the .../acme/dnsapi/. folder.
Give execution rights to the dns_zoneedit.sh file, e.g.
```
chmod +x .../acme/dnsapi/dns_zoneedit.sh
```

Update the .../acme/acme.inc with:
```
$acme_domain_validation_method['dns_zoneedit'] = array('name' => "DNS-Zoneedit",
        'fields' => array(
                'ZONEEDIT_ID' => array('name' => "zoneedit_id", 'columnheader' => "ID", 'type' => "textbox",
                        'description' => "ZONEEDIT ID"
                ),
                'ZONEEDIT_Token' => array('name' => "zoneedit_token", 'columnheader' => "Token", 'type' => "textbox",
                        'description' => "ZONEEDIT Token"
                        )
        ));
```
just before //TODO add more challenge validation types

### Pfsense usage:
Use the pfsense webgui for acme certifictes select method DNS-Zoneedit. Enter ID and token.

## Limitations
There is no endpoint to remove the challenge(s). Thus one have to remove the challenges from time to time.

## Improvements
* Replace the usage of the get method to post inorder to get better protection of id and token.
* Provide diff file and a script to update the acme.inc file in pfsense
