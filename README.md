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

There is now an endpoint to remove the challenge(s).

Credits to github user onley for adding support for the txt-delete endpoint.


There are two different installation methods one for an ordinray bash / sh installation and one into [pfsense](https://www.pfsense.org/download/)

## Standalone installation
Install [acme.sh](https://github.com/acmesh-official/acme.sh)

Place the dns_zoneedit.sh file in the .../acme/dnsapi/ folder.
Give execution rights to the dns_zoneedit.sh file, e.g.
```
chmod +x .../acme/dnsapi/dns_zoneedit.sh
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
Note: acme.sh has changed the default CA (Certficate Authority) to ZeroSSL. The CA can be changed for example to let's encrypt with:

```
acme.sh --set-default-ca letsencrypt --issue --dns dns_zoneedit -d example.com -d www.example.com
```

Supported CA's can be found here: [supported CA's ](https://github.com/acmesh-official/acme.sh#supported-ca)


## Pfsense installation
Install the acme package. Place the dns_zoneedit.sh file into the /usr/local/pkg/acme/dnsapi/ folder.
Then place the acme_zoneedit_inc.patch into the /usr/local/pkg/acme/ folder.
Give execution rights to the dns_zoneedit.sh file, e.g.
```
chmod +x /usr/local/pkg/acme/dnsapi/dns_zoneedit.sh
```

Update acme.inc by using useing patch e.g:
```
cd /usr/local/pkg/acme
patch -b acme.inc < acme_zoneedit_inc.patch
```
The option b creates a backup file (acme.inc.orig) of acme.inc before patch is applied 


or edit the /usr/local/pkg/acme/acme.inc with (if patching fails):
```
$acme_domain_validation_method['dns_zoneedit'] = [
	'name' => 'DNS-Zoneedit',
	'fields' => [
		'ZONEEDIT_ID' => [
			'name' => 'zoneedit_id',
			'description' => 'ZONEEDIT ID',
			'columnheader' => 'ID',
			'type' => 'textbox',
		],
		'ZONEEDIT_Token' => [
			'name' => 'zoneedit_token',
			'description' => 'ZONEEDIT Token',
			'columnheader' => 'Token',
			'type' => 'textbox',
		],
	]
];
```
just before //TODO add more challenge validation types



### Pfsense usage:
Use the pfsense webgui for acme certificates select method DNS-Zoneedit. Enter ID and token.

## Limitations
In pfsense when acme pakage is updated acme.inc is overwritten, thus it has to be updated with acme_domain_validation_method for dns_zoneedit again. 

## Improvements
* Replace the usage of the get method to post inorder to get better protection of id and token.
  - Implemented 22-12-27
* Provide diff file and a script to update the acme.inc file in pfsense. 
  - Implemented 22-12-27
* dns_zoneedit_add and dns_zoneedit_rm improved and cleaned up 
  - Merged 23-01-02
* README.md added note on changing CA.
  - 23-10-10
* acme.inc have changed format, consequently patch et.c. are updated
  - 24-05-31.

## Aknowledgements
* Thanks to onley for dns_zoneedit_rm
* Thanks to sbn-purchark for mayor improvement of the script.
* Thanks to denix0 for context to acme_zoneedit_inc.patch to avoid recurring failing patches when source was changed. 

## Known issues
* It has been reported that dns_zoneedit_rm reports in false positives in some cases.
* Pfsense integration lacks field with ability to include extra acme.sh commands and parameters.
* Merge of context into acme_zoneedit_inc.patch is untested. If problem arises apply it manually according to above documentation. 
