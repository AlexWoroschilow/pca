<?php

function check_alphanum($field_name_1)
{
	if(!preg_match("/[^a-zA-Z0-9\_:]+$/s",$field_name_1) && strlen($field_name_1) > 0)
		return TRUE;
	else
		return FALSE;
}

function show_subset($name) {
	$call = "perl get_related_pdb.pl ". $name;
	$handle  = popen($call , "r");
	$out = "";
	$i=1;
	while (!feof($handle)) {
		$results = fgets($handle, 4096);
		flush();
		ob_flush();

		usleep(1000);
		$i=$i+1;
		if (strlen($results) == 0) {
			// stop the browser timing out
			echo " ";
			flush();
			ob_flush();
		} else {
			$tok = strtok($results, "\n");
			while ($tok !== false) {
				$out = $out . $tok;
				flush();
				$tok = strtok("\n");
			}
		}
	}
	pclose($handle);
	$members = split(";", $out);
	$k = 0;
	for($i=0; $i < count($members); $i++) {
		echo $members[$i] ." ";
	}
}

extract($_GET);

if (!check_alphanum($chain)) {
	echo "Check the name of the pdb query.";
	$ok = FALSE;
} else {
	$chain = strtolower($chain);
	$chain = preg_replace('/\s\s*/', '', $chain);
	$chain = preg_replace('/\:/', '', $chain);
	// This will be 'foo o' now

	$chain = preg_replace("/NULL/", "_", $chain);
	if (strlen($chain) == 4) $chain .= "_";
	if (strlen($chain) > 5 || strlen($chain) < 4) {
		echo "Check name of the pdb query." . $chain;
		$ok = FALSE;
	}
	if ($chain[strlen($chain)-1] != '_') {
		$chain = substr($chain, 0, strlen($chain)-1) . strtoupper($chain[strlen($chain)-1]);
	}
}

show_subset($chain);
flush();
ob_flush();
?>
