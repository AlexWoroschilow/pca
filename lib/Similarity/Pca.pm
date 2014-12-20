package Similarity::Pca;
use Math::Complex;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Math::Matrix;

sub new () {
  my ( $class, $args ) = @_;
  my $self = {
    pc => $args->{pc},
    r  => new Math::Matrix( @{ $args->{matrix} } ),
    m  => undef,
    p  => undef,
    t  => undef
  };
  return bless $self, $class;
}

sub pca () {
  my $self = shift;
  
  $self->{m} = $self->{r}->clone;
  ( my $n, my $m ) = $self->{m}->size;
  my $threshold = 0.00001;
  foreach my $i ( 0 ... ( $self->{pc} - 1 ) ) {
    my $t  = $self->{m}->slice($i);
    my $P1 = $t->clone;
    my $T1 = $self->{m}->transpose->multiply($P1);
    do {
      $d0 = $T1->transpose->multiply($T1);
      $P1 = $self->{m}->transpose->multiply($t);
      $P1 = $P1->multiply( $t->transpose->multiply($t)->invert );
      $P1 = $P1->normalize;
      $T1 = $self->{m}->multiply($P1);
      $T1 = $T1->multiply( $P1->transpose->multiply($P1)->invert );
      $d1 = $T1->transpose->multiply($T1);
    } while ( $d1->absolute - $d0->absolute > $threshold );
    if ( $i == 0 ) {
      $self->{p} = $P1->clone;
      $self->{t} = $T1->clone;
    }
    else {
      $self->{p} = $self->{p}->concat($P1);
      $self->{t} = $self->{t}->concat($T1);
    }
    $self->{m} = $self->{m}->subtract( $T1->multiply( $P1->transpose ) );
  }
  return 1;
}
1;
