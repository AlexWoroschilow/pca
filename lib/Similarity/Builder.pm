package Similarity::Builder;
use base Exporter;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Text::Xslate;
use Similarity::Pca;
use Similarity::Compare;

sub new ($ \@ \@ $) {
  my ( $class, $args ) = @_;
  my $self = {
    ref1 => $args->{ref1},
    ref2 => $args->{ref2},
    pcc  => $args->{pcc},
  };
  return bless $self, $class;
}

# Compare proteins all to all
# get a result as a multidimensional array
sub all_to_all () {
  my $self = shift;
  
  my @ref1 = @{ $self->{ref1} };
  my @ref2 = @{ $self->{ref2} };

  # Use script from Andrew Torda
  my @matrix = Similarity::Compare::all_to_all( @ref1, @ref2 );

  # Apply PCA to given matrix
  # return all matrixes (raw, rest, P, T)
  my $pca = new Similarity::Pca(
    {
      matrix => \@matrix,
      pc     => $self->{pcc}
    }
  );
  if ( $pca->pca() ) {

    # Build a data structure
    # to push into templater
    my $result = {};
    my ( $m, $n ) = $pca->{t}->size;
    foreach my $i ( 0 ... ( $m - 1 ) ) {
      $result->{"@ref1[$i]"} = {
        "x" => $pca->{t}->[$i]->[0],
        "y" => $pca->{t}->[$i]->[1],
        "z" => $pca->{t}->[$i]->[2],
      };
    }
    return $result;
  }
}

# Build result to xml
# hier can be a another decorator
sub xml ($) {
  my $self = shift;
  my ($collection) = @_;

  # Initialize templater and
  # define folder with template
  my $xslate = Text::Xslate->new( "path" => ["$FindBin::Bin/template"], );

  # build a template to xml
  # output ready xml to console
  return $xslate->render( "matrix.xslate.xml",{ 
    "collection" => $collection 
  });
}
1;
