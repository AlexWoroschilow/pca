<!-- 
* takes xml and xsl paths
* echos HTML
-->

<?php

	// Load xml
	$xml = new DOMDocument();
	$xml->load($_POST["xml"]); 

	// Load xsl
	$xsl = new DOMDocument();
	$xsl->load($_POST["xsl"]);

	// transform
	$xslt = new XSLTProcessor();
	$xslt->importStylesheet($xsl); 
	echo $xslt->transformToXML($xml);


?>
