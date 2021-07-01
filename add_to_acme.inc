/*
 * acme.inc
 *
 * Add the below to the
 *acme_domain_validation_method = array();
 */
$acme_domain_validation_method['dns_zoneedit'] = array('name' => "DNS-Zoneedit",
	'fields' => array(
		'ZONEEDIT_ID' => array('name' => "zoneedit_id", 'columnheader' => "ID", 'type' => "textbox",
			'description' => "ZONEEDIT ID"
		),
		'ZONEEDIT_Token' => array('name' => "zoneedit_token", 'columnheader' => "Token", 'type' => "textbox",
			'description' => "ZONEEDIT Token"
			)
	));
