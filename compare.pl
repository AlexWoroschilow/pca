#!/usr/bin/perl
use Exporter qw(import);
use Similarity::Builder 'all_to_all', 'to_xml';

sub mymain () {

  # Replace 1 to 0
  # for production use
  my $testing = 1;
  use Getopt::Std;

  # Get ref-Proteins
  # from a first string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_ref = split( ',', $ARGV[0] );

  # get test-Proteins
  # from a second string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_test = split( ',', $ARGV[1] );

  # Replace found proteins
  # with a test proteins
  if ($testing) {
    @proteins_ref = ( '5ptiA', '4nkpA', '3fpvB', '4mn7A', '9ptiA' );
    @proteins_test = ( '5ptiA', '2qybA', '3oovB' );
  }
  print to_xml( all_to_all( @proteins_ref, @proteins_test ) );
}
exit( mymain() );
