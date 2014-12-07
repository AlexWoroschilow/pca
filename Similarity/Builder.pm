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
  my ( $proteins_ref, $proteins_test ) = @_;
  my @proteins_ref  = @$proteins_ref;
  my @proteins_test = @$proteins_test;

  # Use script from Andrew Torda
  my (@matrix) =
    Similarity::Compare::all_to_all( @proteins_ref, @proteins_test );

  # Apply PCA to given matrix
  # return all matrixes (raw, rest, P, T)
  ( my $raw, my $matrix, my $P, my $T ) = matrix_to_pca(@matrix);
  return $T;
}

# Apply PCA to given matrix
# return all matrixes (raw, rest, P, T)
sub matrix_to_pca (@) {
  my (@matrix) = @_;

  # Use module from Alex Woroschilow
  return Similarity::Pca::normalized(@matrix);
}

# Build result to xml
sub to_xml ($) {
  my ($T) = @_;

  # Build a data structure
  # to push into templater
  my $result = {};
  my ( $m, $n ) = $T->size;
  foreach my $i ( 0 ... ( $m - 1 ) ) {
    $result->{"@proteins_ref[$i]"} = {
      "x" => $T->[$i]->[0],
      "y" => $T->[$i]->[1],
      "z" => $T->[$i]->[2],
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
