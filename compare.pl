#!/usr/bin/perl
use Salami::PCA;
use Salami::Compare;
use FindBin qw($Bin);
use Text::Xslate;
use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

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

  # compare proteins all to all
  # get a result as a multidimensional array
  my (@matrix) = Salami::Compare::proteins( @proteins_ref, @proteins_test );

  # Apply PCA to given matrix
  # return all matrixes (raw, rest, P, T)
  ( my $raw, my $matrix, my $matrixP, my $matrixT ) = Salami::PCA::raw(@matrix);

  # Build a data structure
  # to push into templater
  my $result = {};
  my ( $m, $n ) = $matrixT->size;
  foreach my $i ( 0 ... ( $m - 1 ) ) {
    $result->{"@proteins_ref[$i]"} = {
      "x" => $matrixT->[$i]->[0],
      "y" => $matrixT->[$i]->[1],
      "z" => $matrixT->[$i]->[2],
    };
  }

  # Initialize templater and
  # define folder with template
  my $xslate = Text::Xslate->new( "path" => ["$Bin/template"], );

  # build a template to xml
  # output ready xml to console
  print $xslate->render( "matrix.xslate.xml", { "collection" => $result } );
}
exit( mymain() );
