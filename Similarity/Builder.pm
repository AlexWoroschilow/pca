package Similarity::Builder;
use base Exporter;
our @EXPORT_OK = ( 'to_xml', 'all_to_all' );
use Similarity::Pca;
use Similarity::Compare;
use FindBin qw($Bin);
use Text::Xslate;

# Compare proteins all to all
# get a result as a multidimensional array
sub all_to_all (\@\@) {
  my ( $ref, $test ) = @_;
  my @ref  = @$ref;
  my @test = @$test;

  # Use script from Andrew Torda
  my (@matrix) = Similarity::Compare::all_to_all( @ref, @test );

  # Apply PCA to given matrix
  # return all matrixes (raw, rest, P, T)
  ( my $raw, my $matrix, my $P, my $T ) = Similarity::Pca::normalized(@matrix);

  # Build a data structure
  # to push into templater
  my $result = {};
  my ( $m, $n ) = $T->size;
  foreach my $i ( 0 ... ( $m - 1 ) ) {
    $result->{"@ref[$i]"} = {
      "x" => $T->[$i]->[0],
      "y" => $T->[$i]->[1],
      "z" => $T->[$i]->[2],
    };
  }
  return $result;
}

# Build result to xml
# hier can be a another decorator
sub to_xml ($) {
  my ($collection) = @_;

  # Initialize templater and
  # define folder with template
  my $xslate = Text::Xslate->new( "path" => ["$Bin/template"], );

  # build a template to xml
  # output ready xml to console
  return $xslate->render( "matrix.xslate.xml",
    { "collection" => $collection } );
}
1;
