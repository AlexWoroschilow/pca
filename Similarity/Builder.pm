package Similarity::Builder;
use base Exporter;
our @EXPORT_OK = ('to_xml');
use Similarity::Pca;
use Similarity::Compare;
use FindBin qw($Bin);
use Text::Xslate;

sub to_xml (\@\@) {
  my ( $proteins_ref, $proteins_test ) = @_;
  my @proteins_ref  = @$proteins_ref;
  my @proteins_test = @$proteins_test;
  return "asdfad\n";

  # Compare proteins all to all
  # get a result as a multidimensional array
  my (@matrix) =
    Similarity::Compare::all_to_all( @proteins_ref, @proteins_test );

  # Apply PCA to given matrix
  # return all matrixes (raw, rest, P, T)
  ( my $raw, my $matrix, my $matrixP, my $matrixT ) =
    Similarity::Pca::normalized(@matrix);

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
  return $xslate->render( "matrix.xslate.xml", { "collection" => $result } );
}
1;
