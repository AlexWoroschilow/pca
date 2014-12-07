# 12 Nov 2014
# To be called by the web server. Compare proteins from one set with all members
# of the second set.

=pod

=head1 NAME

compare_few_prot.pl - Given two sets of proteins, compare all in set A with all in set B

=head1 SYNOPSIS

compare_few_prot.pl PROT1[,PROT2,PROT3,..] PROT_X[,PROT_Y,PROT_Z,...]

=head1 DESCRIPTION

We have a set of reference protein (set A). We have a second set
(B). For each protein in B, we want the distance/difference to each
reference protein.

There may be any number (bigger than zero) of reference
proteins. There may be any nubmer of proteins to be compared against
the reference proteins.

All proteins are given in the form of I<1xyzA> where I<1xyz> is the
pdb acquisition code and I<A> is the chain identifier. This
corresponds with our naming convention for .bin files.

Exactly two comma separated lists should be given. No spaces are
allowed within each list. An invocation might look like

 compare_few_prot.pl 1abcD,1efgH,2defG 1pqrA,2qrsB,5ptiA

In this case, the reference proteins would be I<1abcD>, I<1efgH>,
I<2defG> and the second list would be I<1pqrA>, I<2qrsB>, I<5ptiA>.

=head1 OPTIONS

=over

=item There are not any yet.

=back

=head1 RETURN VALUES

=head2 Happy

How do we give results back to the caller ?

=head2 Unhappy

how do we tell the caller something broke ? If run as a free standing
script, we can use the return value. This script should probably
mutate into a module, in which case we shall return
EXIT_SUCCESS/EXIT_FAILURE.

=head1 NOTES

The exact alignment script that this is based on seems to be
F<~torda/c/wurst/optim/scripts/purestruct_adjust_mshift.pl>.

=cut

use strict;
use warnings;
use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

use FindBin;
use lib "$FindBin::Bin/salamiServer";
use Salamisrvini;

#use lib $LIB_LIB;  #initialize in local Salamisrvini.pm;
#use lib $LIB_ARCH; #initialize in local Salamisrvini.pm;
use lib "$FindBin::Bin/../blib/arch"; # This gives us Wurst.so
use lib "$FindBin::Bin/../lib";       # Gives us Wurst.pm
# ./blib/arch/auto/Wurst/Wurst.so
use Wurst;



1;
