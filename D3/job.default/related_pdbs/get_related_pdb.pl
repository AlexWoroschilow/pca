#!/usr/bin/perl
use DB_File;


$query = $ARGV[0];
#print $query."query\n";


tie %chaintest, "DB_File", "chainhash.db";
tie %clustertest, "DB_File", "clusterhash.db";


my $clusternumber = $chaintest{$query};
print "$clustertest{$clusternumber}";

untie %chaintest;
untie %clustertest;


