<?php

/* 	
 * loads a .json file with an alignment and offers 
 * a fasta file for downloading
 */

/* 
 * get the directory of the .json file (the job-directory) and parse the file-content 
 * into an associative array
 */

//$do_delete = array("~","/","."," ");

$resdir = "../jobs/".$_GET["jobfolder"];
//$resdir = str_replace($do_delete, "", $resdir);

$in = $_GET["alignment"];
//$in = str_replace($do_delete, "", $in);


$alignment = file("$resdir/json/$in.json");
$alignment = implode($alignment);
$json_obj = json_decode($alignment, TRUE);


$filename = "";

$s = sizeof($json_obj["chains"]);
$c = 0;

foreach ($json_obj["chains"] as $id => $sequence){
	$filename.=$id;
	$c = $c+1;
	if($c < $s) $filename .= "_";
}


header('Content-type:application/txt');
header('Content-Disposition:attachment;filename="'.$filename.'.fasta"');
//header('Content-Disposition:attachment;filename="align.txt"');


foreach ($json_obj["chains"] as $id => $sequence){
	$seq_lines = str_split($sequence, 100);
	$seq_lines = implode("\n", $seq_lines);
	$last = count($json_obj[$id."_positions"])-1;
	$sequence_data = ">$id | ".$json_obj[$id."_positions"][0]." - ".$json_obj[$id."_positions"][$last];
	$sequence_data .= "\n$seq_lines\n";
	echo($sequence_data);
}


?>

