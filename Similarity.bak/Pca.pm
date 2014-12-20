package Similarity::Pca;
use Math::Matrix;
use Math::Complex;

sub raw (\@ $) {
  my ( $matrix, $pc ) = @_;
  my @matrix = @$matrix;
  return pca( new Math::Matrix(@matrix), $pc );
}

sub normalized (\@ $) {
  my ( $matrix, $pc ) = @_;
  my @matrix = @$matrix;
  return pca( new Math::Matrix( normalize(@matrix) ), $pc );
}

sub pca ($ $) {
  my ( $raw, $pc ) = @_;
  my $matrix = $raw->clone;
  my $matrixP;
  my $matrixT;
  ( my $n, my $m ) = $matrix->size;
  my $threshold = 0.00001;
  foreach my $i ( 0 ... ( $pc - 1 ) ) {
    my $t  = $matrix->slice($i);
    my $P1 = $t->clone;
    my $T1 = $matrix->transpose->multiply($P1);
    do {
      $d0 = $T1->transpose->multiply($T1);
      $P1 = $matrix->transpose->multiply($t);
      $P1 = $P1->multiply( $t->transpose->multiply($t)->invert );
      $P1 = $P1->normalize;
      $T1 = $matrix->multiply($P1);
      $T1 = $T1->multiply( $P1->transpose->multiply($P1)->invert );
      $d1 = $T1->transpose->multiply($T1);
    } while ( $d1->absolute - $d0->absolute > $threshold );
    if ( $i == 0 ) {
      $matrixP = $P1->clone;
      $matrixT = $T1->clone;
    }
    else {
      $matrixP = $matrixP->concat($P1);
      $matrixT = $matrixT->concat($T1);
    }
    $matrix = $matrix->subtract( $T1->multiply( $P1->transpose ) );
  }
  return @{ [ $raw, $matrix, $matrixP, $matrixT ] };
}

#
# Prepare matrix for PCA method,
# switch colummns and rows,
# render a mean value
# and standart deviation
#
sub normalize (@) {
  my @matrix      = transposition(@_);
  my @average     = average(@matrix);
  my @stdeviation = stdev(@matrix);
  foreach my $i ( keys @matrix ) {
    my @row = @{ $matrix[$i] };
    foreach my $j ( keys @row ) {
      my $mean  = $average[$i];
      my $stdev = $stdeviation[$i];
      my $value = $row[$j];
      $matrix[$i][$j] = ( $value - $mean ) / $stdev;
    }
  }
  return transposition(@matrix);
}

#
# Prepare matrix for PCA method,
# switch colummns and rows,
#
sub transposition {
  my @raw   = @_;
  my @cache = ();
  foreach my $i ( keys @raw ) {
    my @row = @{ $raw[$i] };
    foreach my $j ( keys @row ) {
      push( @cache, [] );
    }
    last;
  }
  foreach my $i ( keys @raw ) {
    my @row = @{ $raw[$i] };
    foreach my $j ( keys @row ) {
      push( $cache[$j], $row[$j] );
    }
  }
  return @cache;
}

#
# Prepare matrix for PCA method,
# render a mean value
#
sub average {
  my (@matrix) = @_;
  my @average = ();
  foreach my $i ( keys @matrix ) {
    my @row = @{ $matrix[$i] };
    my $sum = 0;
    foreach my $item (@row) {
      $sum += $item;
    }
    push( @average, $sum / scalar(@row) );
  }
  return @average;
}

#
# Prepare matrix for PCA method,
# and standart deviation
#
sub stdev {
  my @matrix  = @_;
  my @average = average(@matrix);
  my @stdev   = ();
  foreach my $i ( keys @matrix ) {
    my @row       = @{ $matrix[$i] };
    my $meanStdev = 0;
    foreach my $j ( keys @row ) {
      my $mean  = $average[$i];
      my $value = $row[$j];
      $meanStdev += ( $value - $mean )**2;
    }
    push( @stdev, sqrt( $meanStdev / scalar(@row) ) );
  }
  return @stdev;
}
1;
