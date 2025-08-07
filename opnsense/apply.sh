#/bin/sh

echo Adding Zoneedit.com to OPNsense ACME Challenge Types
cp ../dns_zoneedit.sh /usr/local/share/examples/acme.sh/dnsapi/
cp DnsZoneedit.php /usr/local/opnsense/mvc/app/library/OPNsense/AcmeClient/LeValidation
patch -p0 -i AcmeClient.xml.patch
patch -p0 -i dialogValidation.xml.patch
