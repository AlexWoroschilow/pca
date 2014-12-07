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

    #    @proteins_ref = ( '5ptiA', '4nkpA', '3fpvB', '4mn7A', '9ptiA' );
    #    @proteins_test = ( '5ptiA', '2qybA', '3oovB' );
    @proteins_ref = (
      "1b64A", "1ejfB", "1epgA", "1jyoC", "1k3sA", "1kafB", "1l2wC", "1l2wK",
      "1n4nA", "1pewB", "1r8uA", "1s6uA", "1ti5A", "1tiuA", "1ttwA", "1ulrA",
      "1uw4A", "1v3zB", "1vehA", "1wcjA", "1whwA", "1wmiA", "1xdtR", "1xedB",
      "1xkpB", "1xkpC", "1y3jA", "2a0lF", "2a10E", "2a1bE", "2ad9A", "2b0gA",
      "2b9kA", "2brqB", "2bsiA", "2bz2A", "2cq0A", "2d9rA", "2dclC", "2di8A",
      "2dnzA", "2ekyG", "2fa8D", "2fm8A", "2fy1A", "2g13A", "2g9oA", "2gv1A",
      "2hgmA", "2hltA", "2hyiB", "2ki2A", "2kjwA", "2kx2A", "2kz0A", "2l60A",
      "2nqcA", "2nzcA", "2obkB", "2od0A", "2okaB", "2otuD", "2pq4A", "2q87B",
      "2vsdA", "2w0pA", "2w7vA", "2xgaA", "2ywkA", "2zbcC", "2zztA", "3b4mC",
      "3bn4E", "3bs9B", "3cnkA", "3dwaD", "3epuA", "3g7lA", "3g9wD", "3h2vH",
      "3hi9D", "3hshC", "3kxyG", "3lpyA", "3lyvF", "3mcdA", "3mpwK", "3n3fA",
      "3ngkA", "3njpC", "3p6yL", "3psmB", "3qt1I", "3r27B", "3s7rB", "3ulhA",
      "3zzzA", "4a94D", "4akxA", "4tgfA",
    );
    @proteins_test = @proteins_ref;
  }
  print to_xml( all_to_all( @proteins_ref, @proteins_test, 3 ) );
}
exit( mymain() );
