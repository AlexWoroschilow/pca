#!/usr/bin/perl
##$ -clear
#$ -w e
##$ -l arch=glinux -l short=0
#$ -p -50
#$ -S /home/torda/bin/perl
#$ -cwd
#$ -j y
#$ -m e -M margraf@zbh.uni-hamburg.de
#$ -q stud.q 

=pod

=head1 NAME

libsrch.pl - Given a structure, align it to a library of templates

=head1 SYNOPSIS

libsrch.pl [options] I<struct_file> I<struct_lib_list> 


=head1 DESCRIPTION

Given a structure, align it to every member of a library of
templates.  
=head2 FILE FORMAT

The list of files which make up the template library is in a
simple format. The script will try to read anything that looks

like a four-letter protein name + chain id from the first
column. Leading white space is ignored. A valid form would look
like

   1abc_
   2qrsB
   1xyz  This text after first column is ignored

=head2 Changing library and templates.

Typically, a first run will be made with whatever library we are
using. However, one will often want to add extra .bin files
for a particular sequence. To do that,

=over

=item *

Add the new file names to the list of proteins and give it a name
like F<mylist>.

=item *

Make a directory with a name like I<templates> and put the extra
F<.bin> files in there.

=item *

Run the script with the B<-t> option like:

  perl libsrch.pl -t templates blahblah.seq mylist

=back

=head2 OPTIONS

=over

=item B<-a> I<N>

Print out details of the best I<N> alignments.

=item B<-d> I<modeldir>

Save final models in I<modeldir> instead of the default
directory, B<modeldir>.

=item B<-h> I<N>

After doing alignments, a default number (maybe 50) will be
printed out. Alternatively, you can ask for the I<N> best scoring
alignments to be printed out.

=item B<-m> I<N>

After alignments, I<N> models will be built, otherwise, a small
default number will appear. Set I<N> to zero if you do not want
any models.

=item B<-s>

Do not use secondary structure predictions. This will cause a
different set of parameters to be used in the calculation.

=item B<-t> I<dir1[,dir2,...]>

Add I<dir1> to the list of places to look for template
files. This is a comma separated list, so you can add more
directories.

=back

=head1 OUTPUT

In all output

=over

=item *

B<SW> refers to the result of the second Smith and Waterman.

=item *

B<NW> refers to the result of the Needleman and Wunsch.

=item *

B<cvr> or B<cover> refers to "coverage".  This is the fraction of
sequence residues which are aligned to part of a
structure. Continuing, B<S<sw cvr>> refers to coverage from the
Smith and Waterman calculation.

=item *

The script prints out the coverage in a somewhat pictorial form
which might look like

   ----XXXXX---XXX

where the X's mean a residue was aligned.

=back

=head1 MODELS

Models will be written in PDB format for the best few
sequences. They will get written to a directory called
F<modeldir>. Maybe this should be made an option.

=head1 OPERATION

Currently the script does

=over

=item Smith and Waterman step 1

This is a locally optimal alignment.

=item Smith and Waterman step 2

This is another locally optimal alignment, but forced to pass
through the same path as the first one. It provides a small
extension to the alignment.

=item Needleman and Wunsch

This is a globally optimal alignment, but forced to pass through
the preceding Smith and Waterman.

=back

=head1 QUESTIONS and CHANGES

=item *

The selection of which scores to print out is a bit arbitrary.

=item *

the coverage picture is very ugly. It could be
beautified.

=item *

The coverage picture corresponds to the Smith and
Waterman. Perhaps it should be the Needleman and
Wunsch. Obviously, both are possible, but just a bit ugly.

=cut


# use lib "/home/other/wurst/salamiServer/wurst/blib/lib";
# use lib "/home/other/wurst/salamiServer/wurst/blib/arch";  
#von Iryna
use Salamisrvini;
use lib $LIB_LIB;  #initialize in local Salamisrvini.pm;
use lib $LIB_ARCH; #initialize in local Salamisrvini.pm;
use Wurst;

use FindBin;
use lib "$FindBin::Bin/pca";
use Similarity::Builder; #ALEX


use vars qw ($MATRIX_DIR $PARAM_DIR
  $RS_PARAM_FILE $FX9_PARAM_FILE );

if ($@) {
    die "broke reading paths.inc:\n$@";
}
if ( defined( $ENV{SGE_ROOT} ) ) {
    $MATRIX_DIR = "$ENV{HOME}/../../torda/c/wurst/matrix";
    $PARAM_DIR  = "$ENV{HOME}/../../torda/c/wurst/params";
}

use strict;

use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

# Iryna 
#global variable for using the combined or the single ca/strct functions
our $function;

# ----------------------- Defaults  ---------------------------------
# These are numbers you might reasonably want to change.
# They should (will) be changeable by options.
use vars qw ($N_BRIEF_LIST $N_MODELS $N_ALIGNMENTS $DFLT_MAX_ATTACH $MAG_NUM_ASREST);
$N_BRIEF_LIST = 100;
$N_MODELS     = 5;
$N_ALIGNMENTS = 5;
$DFLT_MAX_ATTACH = 5;
$MAG_NUM_ASREST = 50;
#changed by Iryna
# use vars qw ($modeldir $DFLT_MODELDIR $PVEC_STRCT_DIR $classfile);
use vars qw ($modeldir $DFLT_MODELDIR);
*DFLT_MODELDIR = \'modeldir';
$modeldir      = $DFLT_MODELDIR;

#changed von Iryna ------------------
# This is a top level temporary directory. We can have a cron job
# run around and clean it up at night. Each job creates its own
# temporary directory under this one.
# use vars qw ($log_base $TOP_TEMP $RESDIR $jscriptspath $RESURL $OUTURL);
# *TOP_TEMP   = \"/home/other/wurst/wurst_delete_able_temp";
# *RESDIR = \"/home/other/wurst/salamiServer/results/";
# # on flensburg
# *OUTURL = \"/home/other/wurst/public_html/salami/version_2/results/jobs";
# *RESURL = \"http://flensburg.zbh.uni-hamburg.de/~wurst/salami/version_2/results";
# # Where we will write logs to
# *log_base   = \"log";
# *jscriptspath = \"/home/other/wurst/public_html/salami/version_2/results/";


# Define our mail program, reply-to address and from address.
use vars qw ($mail_from_addr $mail_reply_to $mail_prog);
*mail_from_addr = \'"Wurst results" <nobody@zbh.uni-hamburg.de>';
*mail_reply_to  = \'nobody@zbh.uni-hamburg.de';
*mail_prog      = \'/usr/bin/mail';

# Switches..
# During testing, we do not want to be able to switch off things
# like the calculation, mailing... These are turned on and off
# here.

use vars qw ($redirect_io $really_mail
             $do_the_calculation $fake_args $verbose);
my $nothing = undef;
*redirect_io  =       \1;
*really_mail  =       \1;
*do_the_calculation = \1;
*fake_args          = \$nothing;
*verbose            = \$nothing;
undef $nothing;

# ----------------------- Global variables  -------------------------
# Unfortunately, we need to store some things here, mainly in
# case we have to quickly die. The bad_exit() routine can mail
# back something informative if it knows the address and job
# title.
use vars qw ($email_address $tmp_dir $title);

# ----------------------- Sequence Alignment Constants -----------------------
# These are declared globally, and set by set_params().
# changed by Iryna  
use vars qw (
  $align_type
  $sw1_pgap_open
  $sw1_qgap_open
  $sw1_pgap_widen
  $sw1_qgap_widen
  $s_const
  $s_factor
  $weight
  $gauss_err
  $tau_error
  $ca_dist_error
  $corr_num
  $m_s_scale
  $m_shift
);

# These parameters will be used for extending alignments via a
# Needleman and Wunsch

use vars qw (
  $nw_pgap_open
  $nw_qgap_open
  $nw_pgap_widen
  $nw_qgap_widen
  $nw_sec_pnlty
);

#commented by Iryna
# use vars qw( @DFLT_STRUCT_DIRS  @PROFILE_DIRS
#   $BIN_SUFFIX );
# *DFLT_STRUCT_DIRS = ['.', '/smallfiles/public/no_backup/bm/pdb_all_bin'];
# *BIN_SUFFIX       = \'.bin';

# ----------------------- set_params    -----------------------------
# This gets its own function because it can be more complicated
# if, in the future, we have a version depending on various
# options like whether or not we have secondary structure
# information.
# pgap controls penalties in the sequence, qgap in the structure.

sub set_params () {
#    changed by Iryna
#     *sw1_pgap_open  = \3.25;
#     *sw1_pgap_widen = \0.8942;
    *sw1_pgap_open  = \1.915;
    *sw1_pgap_widen = \1.85;
    *sw1_qgap_open  = \$sw1_pgap_open;
    *sw1_qgap_widen = \$sw1_pgap_widen;
    *m_shift        = \-0.1;
    *s_factor       = \-0.003186;
    *s_const        = \-0.03642;
    *weight         = \0.7642;
    *gauss_err      = \0.4;

    *tau_error      = \0.15;
    *ca_dist_error  = \0.385;
    *corr_num       = \4;
    *m_s_scale      = \0;
    *m_shift        = \0;
    *nw_pgap_open  = \$sw1_pgap_open;
    *nw_qgap_open  = \$sw1_qgap_open;
    *nw_pgap_widen = \$sw1_pgap_widen;
    *nw_qgap_widen = \$sw1_qgap_widen;
}

# ----------------------- log_job   ---------------------------------
# Minimal logging of job.
# We just save the first few characters of the title. It is useful
# for checking jobs from eva/livebench.
# The title gets single quotes, since it is the only thing with a
# totally unpredictable amount of white space.
# The arguments should be
# email_address, 'start' or 'end', title.
sub log_job ($ $ $)
{
    my ($addr, $text, $title) = @_;


    $title =~ s/^ +//;                 # Remove leading white space
    $title = substr ($title, 0, 15);
    $title = "'$title'";
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $iddst) =
        localtime (time());
    $mon +=1;
    $year += 1900;
    #changed by Iryna
#     my $name = "${log_base}_${mday}_${mon}_${year}";  # Our file name
    my $name = "${LOG_BASE}_${mday}_${mon}_${year}";  # Our file name
    my $hostname = `uname -n`;
    chomp $hostname;
    my $logtext = "$addr $text ". localtime (time()). " $hostname $title\n";
    if ( ! (open (LOGFILE, ">>$name"))) {
        print STDERR "Failed logging to $name\n"; return; }
    print LOGFILE $logtext;
    close (LOGFILE);
    return 1;
}

# ----------------------- get_prot_list -----------------------------
# Go to the given filename and get a list of proteins from it.
sub get_prot_list ($) {
    my $f = shift;
    my @a;
    if ( !open( F, "<$f" ) ) {
        print STDERR "Open fail on $f: $!\n";
        return undef;
    }

    while ( my $line = <F> ) {
        chomp($line);
        my @words = split( ' ', $line );
        if ( !defined $words[0] ) { next; }
        $line = $words[0];
        $line =~ s/#.*//;     # Toss comments away
        $line =~ s/\..*//;    # Toss filetypes away
        $line =~ s/^ +//;     # Leading and
        $line =~ s/ +$//;     # trailing spaces.
        if ( $line eq '' ) {
            next;
        }
        substr( $line, 0, 4 ) = lc( substr( $line, 0, 4 ) );    # 1AGC2 to 1agc2
        if ( length($line) == 4 ) {    # Convert 1abc to 1abc_
            $line .= '_';
        }
        push( @a, $line );
    }
    close(F);
    return (@a);
}

# ----------------------- get_path  ---------------------------------
# We have a filename and a list of directories where it could
# be. Return the path if we can find it, otherwise return undef.
sub get_path (\@ $) {
  my ( $dirs, $fname ) = @_;
  foreach my $d (@$dirs) {
    my $p = "$d/$fname";
    if ( -f $p ) {
      return $p;
    }
  }
  return undef;
}

# ----------------------- check_dirs --------------------------------
# Given an array of directory names, check if each one
# exists. Print something if it is missing, but do not give
# up. It could be that there is some crap in the command line
# args, but all the important directories are really there.
# This function is potentially destructive !
# If a directory does not seem to exist, we actually remove it
# from the array we were passed.  This saves some futile lookups
# later on.
sub check_dirs (\@) {
    my $a    = shift;
    my $last = @$a;
    for ( my $i = 0 ; $i < $last ; $i++ ) {
        if ( !-d $$a[$i] ) {
            print STDERR "$$a[$i] is not a valid directory. Removing\n";
            splice @$a, $i, 1;
            $last--;
            $i--;
        }
    }
}

# ----------------------- check_files -------------------------------
# We are given an array of directories and and array of protein
# names and an extension.
# Check if all the files seem to be there.
sub check_files (\@ \@ $) {
    my ( $dirs, $fnames, $ext ) = @_;
    my $errors = 0;
    foreach my $f (@$fnames) {
        my $name = "$f$ext";
        if ( !get_path( @$dirs, $name ) ) {
            $errors++;
            print STDERR "Cannot find $name\n";
        }
    }
    return $errors;
}

# ----------------------- usage   -----------------------------------
sub usage () {
    print STDERR "Usage: \n    $0 -q query_struct_file -l struct_library \n";
    print STDERR "Optional parameters:\n    -a # of Alignments printed\n";
    print STDERR "    -s # of superimposed structures written\n";
    print STDERR "    -h # of results in the list\n";
    print STDERR "    -d directory structures are written to\n";
    exit(EXIT_FAILURE);
}

# ----------------------- get_scores --------------------------------
sub get_scores ($ $ $ $) {
    my ( $pair_set, $coord1, $coord2, $to_use ) = @_;

    my ( $scr_tot, $coverage, $score1, $geo_gap, $score1_gap );
    my ( $str1, $crap );
    my ( $open_cost, $widen_cost, $nseq_gap );
    ( $score1_gap, $score1 ) = pair_set_score($pair_set);
    ( $str1,       $crap )   =
      pair_set_coverage( $pair_set, coord_size($coord1), coord_size($coord2) );
    $coverage = ( $str1 =~ tr/1// );    # This is coverage as an integer
    $coverage =
      $coverage / seq_size( coord_get_seq($coord1) )
      ;                                 #and as fraction of query structure

    my ( $k_scr2, $k_gap_geo, $k_seq_gap, $k_str_gap, $k_str_wdn );

    if ( $coverage < .05 ) {
        $geo_gap    = 0;
        $nseq_gap   = 0;
        $open_cost  = 0;
        $widen_cost = 0;
    }
    else {
        ( $open_cost, $widen_cost ) = pair_set_gap( $pair_set, 1, 1 );
    }

    $k_str_gap = 1 * $sw1_pgap_open;
    $k_str_wdn = 1 * $sw1_pgap_widen;

    $scr_tot = $score1 + $k_str_gap * $open_cost + $k_str_wdn * $widen_cost;
    return ( $scr_tot, $coverage, $score1, $score1_gap, $nseq_gap, $open_cost );
}


# ----------------------- mail_file   -------------------------------
# I do not yet know the best way to send mail. We could reasonably
# We use "nail" because it handles attachments easily.
# Because it is so difficult and messy, all mail should be routed
# through here.
# Return 1 on success, undef otherwise.
sub mail_file ($ $ $ \@)
{
    my ($textfile, $subject, $address, $attachments) = @_;
    $ENV{sendwait} = '1';    # Might persade mailer to finish before returning
    $ENV{encoding} = '8bit'; # Otherwise mailer thinks about quoted-printable

    if ( ! defined ($address)) {
        print STDERR "No address found ! $subject $address\n"; return undef;}

    if ( ! -f ($textfile)) {
        print STDERR ('Cannot find mail file ! $subject $address'); return undef;}

    my @cmdline = $mail_prog;

    if ( defined ($subject)) {
        push (@cmdline, '-s', $subject); }

    foreach my $a (@$attachments) {
        if ( ! -f $a ) {
            print STDERR "model $a disappeared $subject $address\n"; }
        push (@cmdline, '-a', $a);
    }

    if ($textfile) {
        push (@cmdline, '-q', $textfile); }

    push (@cmdline, '-r', $mail_from_addr);
    push (@cmdline, $address);
    my $mail_ret = 0;

    if ($really_mail) {
        open (MAIL, '|-', @cmdline);
        close (MAIL);
        $mail_ret = $?;
    } else {
        open (STDOUT, ">del_me_out");
        open (STDERR, ">del_me_err");
        open (CRAP, "<$textfile");
        while (<CRAP>) {print };
        print " I would invoke @cmdline\n";
        close (STDERR); close (STDOUT);
        $mail_ret = 0;
    }
    wait;
    if ($mail_ret != 0) {
        return undef;}
    else {
        return 1;}
}

# ----------------------- close_up_and_mail -------------------------
# This could be a happy or unhappy exit.
# Grab any files we can find and send them away.
sub close_up_and_mail ($ $ $)
{
    my ($subject, $address, $max_attach) = @_;

#   Send back the model files...
    my @flist = ();
    if ( ! opendir (MODELS, $modeldir)) {
        $max_attach = 0;
    } else {
        @flist = grep (!/^\.$|^\.\.$/, readdir(MODELS));
        closedir (MODELS);
    }
#   Now, we send back our output.
#   From here on, we run the risk of losing error messages.
#   Anything from this point will go to a general error file.
    #   close (STDERR);
    close (STDOUT);
    open (STDERR, ">>emergency_wurst_error");
    open (STDOUT, ">>emergency_wurst_stdout");
    restore_handlers();
    my @nothing = ();
    if ($max_attach == 0) {
        mail_file ("$tmp_dir/tempout", $subject, $address, @nothing);
    #    for (my $i = 0; $i < @flist; $i++) {
    #        my $s = 'Model '. ($i+1) . ' of ' . @flist .
    #            ' on ' . $flist[$i] . " from $subject";
    #        mail_file ("$modeldir/$flist[$i]", $s, $address, @nothing);
    #    }
    } else {
        my $count = 1;
        my $total = int (@flist / $max_attach);
        if (($total * $max_attach) < @flist) {$total++;}
        while (@flist) {
            my @x = splice (@flist, 0, $max_attach);
            map ($_ = "$modeldir/$_", @x);
            my $s = "$subject, part $count of $total";
            if ( !(mail_file ("$tmp_dir/tempout", $s, $address, @x))) {
                my $host = hostname();
                print STDERR "Mail bust. $host";
            }
            $count++;
        }
    }
}



# ----------------------- bad_exit ----------------------------------
# This will run in a server, so if something goes wrong, we
# should at least mail back an indication.  The single parameter
# should be the error message returned by the function which was
# unhappy.
# Should we print to stderr or stdout ?
# This should not matter since we have grabbed both file handles.
sub bad_exit ( $ )
{
    my $msg = shift;
    restore_handlers();  # otherwise an ugly loop is possible
    print STDERR "Error: \"$msg\"\n";
    if (! defined ($title)) {
        $title = 'unknown'; }
    my $subject = "Failed calculating on $title";
    my @attach = undef;
    if (defined ($email_address)) {
        close_up_and_mail ($subject, $email_address, @attach) ;}
    else {
        ;        # Here, we should write to syslog or something.
    }
    exit (EXIT_FAILURE);
}


# ----------------------- get_alt_scores ---------------------------------
# calculates scores on random paths through the scoring matrix
# parameters: number_of_paths/scores, scoring_matrix, pair_set_of_optimal_path
# return: the scores
sub get_alt_scores($ $ $) {
    my ( $num_scrs, $scr_mat, $pair_set ) = @_;
    my @scr_fin;

    for ( my $i = 0 ; $i < $num_scrs ; $i++ ) {
        $scr_fin[$i] = find_alt_path_score_simple( $scr_mat, $pair_set );
    }

    return \@scr_fin;
}

# ----------------------- normalize_alt_scores ------------------------------
#
sub normalize_alt_scores($) {
    my ($scrs_ref) = @_;
    my $mean = 0.0;

    foreach my $scr ( @{$scrs_ref} ) {
        $mean += $scr;
    }
    $mean /= @$scrs_ref;

    my $deviation = 0.0;

    foreach my $scr (@$scrs_ref) {
        my $tmp = $scr - $mean;
        $deviation += ( $tmp * $tmp );
    }
    $deviation /= ( @$scrs_ref - 1 );
    $deviation = sqrt($deviation);

    return ( $mean, $deviation );
}

# ----------------------- get_dme_thresh ----------------------------
# Given an alignment and two proteins, return the thresholded DME
sub get_dme_thresh ($ $ $) {
    my ( $pair_set, $c1, $c2 ) = @_;
    my $model = make_model( $pair_set, coord_get_seq($c1), $c2 );
    if (! $model) {
#       The next message is commented out. The C code already 
#       writes to STDOUT.
#       print STDERR "Found a broken model ", coord_name($c1), ' ', coord_name($c2), "\n";
        return 0.0;
    }
    if ( coord_size($model) < 10 ) {
        return 0.0;
    }
    my $frac;
    if ( !dme_thresh( $frac, $c1, $model, 3.0 ) ) {
        print STDERR "dme_thresh broke.\n";
    }
    return ($frac);
}

# ----------------------- do_align ----------------------------------
# This does the alignment. Although it takes secondary structure
# data as an argument, we are not yet using this in our server
# script.
sub do_align ($ $ $ $ $ $) {
#changed by Iryna
#     my ( $coord1, $coord2, $pvec1, $pvec2 ) = @_;
    my ($matrix_ca,$matrix_strct,$tot_matrix) = 0;
    my ( $coord1,$coord2,$pvec1_strct,$pvec2_strct,$pvec1_ca,$pvec2_ca)= @_;
    
    my $seq_ptr1 = coord_get_seq($coord1);
    my $seq_ptr2 = coord_get_seq($coord2);

    #changed by Iryna
    # build score matrix
#     my $matrix = score_mat_new( seq_size($seq_ptr1), seq_size($seq_ptr2) );
# 
#     score_pvec( $matrix, $pvec1, $pvec2);
#     $matrix = score_mat_shift( $matrix, $m_shift );

    if ($function == 1 || $function == 0) {
        $matrix_ca =
            score_mat_new( seq_size($seq_ptr1), seq_size($seq_ptr2) );
        score_pvec( $matrix_ca,    $pvec1_ca,    $pvec2_ca );
    }
    if ($function == 2 || $function == 0) {
        $matrix_strct =
            score_mat_new(seq_size($seq_ptr1),seq_size($seq_ptr2) );
#        print STDERR "p2 is $pvec2_strct p1 is $pvec1_strct\n";
        score_pvec( $matrix_strct, $pvec1_strct, $pvec2_strct );
    }

     # shift and score matrix
    my $smallsize = (coord_size($coord1) > coord_size($coord2)
                      ? coord_size($coord2) : coord_size($coord1));
    my $shift = ($s_factor * $smallsize) + $s_const;
    if ($function == 0) {
        $tot_matrix =
            score_mat_add ($matrix_ca, $matrix_strct, $weight, $shift);
    } elsif ($function == 1) {
        $tot_matrix = score_mat_shift($matrix_ca, $shift);
    } else {
        # Andrew got another routine for the shift:
        my $scaler = $m_s_scale * $smallsize * 0.001;
        $tot_matrix = score_mat_shift($matrix_strct, $m_shift + $scaler);
    }
    #end change
    my (
        $sw_scr_tot,    $sw_coverage, $sw_score1,
        $sw_score1_gap, $sw_seq_gap,  $sw_strct_gap
    );
    my (
        $nw_scr_tot,    $nw_coverage, $nw_score1,
        $nw_score1_gap, $nw_seq_gap,  $nw_strct_gap
    );

    my $sw_pair_set = score_mat_sum_smpl(
        my $crap_mat,   $tot_matrix,   $sw1_pgap_open, $sw1_pgap_widen,
        $sw1_qgap_open, $sw1_qgap_widen, $S_AND_W
        #$sw1_qgap_open, $sw1_qgap_widen, $N_AND_W
    );

    (
        $sw_scr_tot,    $sw_coverage, $sw_score1,
        $sw_score1_gap, $sw_seq_gap,  $sw_strct_gap
      )
      = get_scores( $sw_pair_set, $coord1, $coord2, 's_and_w' );
      #= get_scores( $sw_pair_set, $coord1, $coord2, 'n_and_w' );
    my $frac_dme = get_dme_thresh( $sw_pair_set, $coord1, $coord2 );

    my $num_scrs     = 1000;
    my $alt_scrs_ref = get_alt_scores( $num_scrs, $tot_matrix, $sw_pair_set );

    my ( $mean, $deviation ) = normalize_alt_scores($alt_scrs_ref);

    undef($alt_scrs_ref);
    my $z_scr;
    if ( $deviation != 0 ) {
        $z_scr = ( $sw_scr_tot - $mean ) / $deviation;
    }
    else {
        $z_scr = 0.0;
    }    # Should not really happen

    #   If the alignment is tiny, one can get a ridiculous z-score
    if ( $sw_coverage < 0.03 ) {    # silently wipe these guys out
        $z_scr = 0.0;
    }

    my $sec_strct_pnlty = 0.0;
    my $newcoord;
    # ====== added for multiple alignment
    my $name;
    my $vectors;
    my $seq;
    my $rmsd;
    # ====================================
    
    my $patscor;
    my @r = (
        $sw_scr_tot, $rmsd, $nw_scr_tot,  $sw_coverage, $nw_coverage,
        $sw_score1,  $nw_score1,   $sw_pair_set, $z_scr, $frac_dme,
        $newcoord, $name, $vectors, $seq, $patscor
    );
    return ( \@r );
}

# ----------------------- zero_shift_mat ----------------------------
# This shifts a substitution matrix, not an alignment score matrix.
sub zero_shift_mat ($ $) {
    my ( $sub_mat, $shift ) = @_;
    for ( my $i = 0 ; $i < 20 ; $i++ ) {
        for ( my $j = $i ; $j < 20 ; $j++ ) {
            my $t = sub_mat_get_by_i( $sub_mat, $i, $j ) + $shift;
            sub_mat_set_by_i( $sub_mat, $i, $j, $t );
        }
    }
}


#added by Iryna
#------------------------ read_struct --------------------------------
sub read_struct_pl ($ $) {
   my ($vecname, $coord1) = @_;
   my ($pvec_strct, $pvec_ca);
   if ($function == 1 || $function == 0) {
        my $vecfile_ca = "$PVEC_CA_DIR/$vecname.vec";
        if ( -e $vecfile_ca){
           $pvec_ca = prob_vec_read($vecfile_ca);
        } else {
            #my $CA_CLASSFILE =
            #    '/cluster/ploeffler/wurst_server/clssfcns/F7_ca';
            my $ca_classfcn = ac_read_calpha ($CA_CLASSFILE, $tau_error,
                                                   $ca_dist_error, $corr_num);
           $pvec_ca = calpha_strct_2_prob_vec($coord1, $ca_classfcn);
        }
    }
    if ($function == 2 || $function == 0) {
        my $vecfile_strct = "$PVEC_STRCT_DIR/$vecname.vec";
        if ( -e $vecfile_strct){
           $pvec_strct = prob_vec_read($vecfile_strct);
        } else {
            #my $strct_classfile =
            #    '/cluster/ploeffler/wurst_server/clssfcns/F6_struct';
            my $strct_classfcn =
                                aa_strct_clssfcn_read($CLASSFILE,$gauss_err);
           $pvec_strct = strct_2_prob_vec($coord1, $strct_classfcn);
        }
   }
   
   return ($pvec_strct, $pvec_ca);
}
# ----------------------- do_lib  -----------------------------------
# Walk over a library, doing alignments and saving interesting
# scores. The definition of interesting is a bit arbitrary.
# There is one very non-obvious coding trick.  We need to be able
# to pass the score information into the sorting functions. We
# could put everything into a big, two-dimensional array, but we
# can avoid copying data. Instead, we invent a package and put
# results into @r::r. The downside is that we have to manually
# free it up at the end by calling undef().
# The $formatflag argument is used for cases like the livebench
# server for whom we have to do a bit of file re-writing.
sub do_lib (\@ \@ $ $ $ $ $ $ $ $ $) {
    my ( $structlist, $struct_dirs, $query_struct, $coord1, $title,
        $formatflag, $rmsd_thresh, $minFragDME, $maxItNum, $jobfolder, $add_to_calc) = @_;
    my (@pair_sets);
    my ($vecname,$coord2,$pvec1_strct,$pvec1_ca, $pvec2_strct, $pvec2_ca);
    use File::Basename;
#     my ($coord2, $pvec1, $pvec2);
    my $vecname = basename($query_struct, ".bin");
#     my $vecfile = "$PVEC_STRCT_DIR/$vecname.vec";
    my $queryseq = coord_get_seq($coord1);

    #changed by Iryna
#     if ( -e $vecfile){
# #        print "vecfile exists \n";
#         $pvec1 = prob_vec_read($vecfile);
#     }
#     else {
# #        print "$vecfile not found -recalculating.\n";
#         my $gauss_err = 0.4;
#         #my $classfile = '/home/other/wurst/salami_lib/classfile';
#         my $classfcn = aa_strct_clssfcn_read($classfile, $gauss_err);
# 	    $pvec1 = strct_2_prob_vec($coord1, $classfcn);
#     }
#      print STDERR "reading of coord1 structors \n";
    ($pvec1_strct, $pvec1_ca) = read_struct_pl($vecname, $coord1);


    my $minsize = seq_size( coord_get_seq($coord1) );
    for ( my $i = 0 ; $i < @$structlist; $i++) {
        #changed by Iryna
#         if ( -e "$PVEC_STRCT_DIR/$$structlist[$i].vec"){
#             $pvec2 = prob_vec_read("$PVEC_STRCT_DIR/$$structlist[$i].vec");
#         }
#         else {
#             print "$PVEC_STRCT_DIR/$$structlist[$i].vec not found\n";
#         }
        if ($function == 1 || $function == 0) {
            if ( -e "$PVEC_CA_DIR/$$structlist[$i].vec"){
                #print STDERR ">>> $PVEC_CA_DIR/$$structlist[$i].vec \n";
                $pvec2_ca =
                    prob_vec_read("$PVEC_CA_DIR/$$structlist[$i].vec");
            } else {
                print STDERR "$PVEC_CA_DIR/$$structlist[$i].vec not found\n";
                return EXIT_FAILURE;
            }
        }
        if ($function == 2 || $function == 0) {
            if ( -e "$PVEC_STRCT_DIR/$$structlist[$i].vec"){
                $pvec2_strct = prob_vec_read
                                ("$PVEC_STRCT_DIR/$$structlist[$i].vec");
            } else {
                print STDERR
                    "$PVEC_STRCT_DIR/$$structlist[$i].vec not found\n";
                return EXIT_FAILURE;
                }
        }
        #end changes
          
        $coord2 =
          coord_read(
            get_path( @$struct_dirs, $$structlist[$i] . $BIN_SUFFIX ) );
        #added by Iryna
        if ($function == 1) { # undefine the unused pvec
            $pvec1_strct = undef;
            $pvec2_strct = undef;
        } elsif ($function == 2) {
            $pvec1_ca = undef;
            $pvec2_ca = undef;
        }

        $r::r[$i] = do_align( $coord2, $coord1, $pvec2_strct, $pvec1_strct,
                                                $pvec2_ca,    $pvec1_ca );
        
        $r::r[$i][4] =
          get_seq_id_simple( $r::r[$i][7], coord_get_seq($coord2),
            coord_get_seq($coord1) );
        $r::r[$i][6] = $r::r[$i][3] * seq_size( coord_get_seq($coord2) );
        if ( $r::r[$i][6] < 25 ) {
            $r::r[$i][8] = 0;
        }
        $r::r[$i][2] = $r::r[$i][9] * ( ( $r::r[$i][6] ) / $minsize );
        $r::r[$i][11] = $r::r[$i][6] ** $r::r[$i][9];
        
    }

    my @indices;
    for (my $i = 0 ; $i < @$structlist ; $i++ ) {
        $indices[$i] = $i;
    }
# changed by Iryna
#     @indices = sort { $r::r[$b][2] <=> $r::r[$a][2]; } @indices;
    @indices = sort { $r::r[$b][11] <=> $r::r[$a][11]; } @indices;
    
    my $htmldir = $RESDIR.$jobfolder;
    my $mkdret = mkdir $htmldir;
    if ($mkdret != 1) {
       print STDERR "makedir failure $jobfolder in  $RESDIR. Must die.";
       return EXIT_FAILURE;
    }
    $htmldir =~ s/\n$//;
    mkdir("$htmldir/modeldir");
    mkdir("$htmldir/json");
    my $htmlbase = `basename $htmldir`;
    my $url = "$RESURL/jobs/$htmlbase/index.html";
    print "SALAMI has finished searching proteins similar to $vecname.\n";
    print " Your results can be viewed in our interactive results browser at:\n"; 
    print " $url\n";
    coord_2_pdb("$htmldir/modeldir/$vecname.pdb", $coord1);
    open XML, ">$htmldir/results.xml";

    #my $todo = ( @$structlist > $N_BRIEF_LIST ? $N_BRIEF_LIST : @$structlist );
    my $todo = ( @$structlist > $maxItNum ? $maxItNum : @$structlist );

    print XML "
<query>

 <params>
   <structure>$vecname</structure>
   <title>$title</title>
   <rmsd_thresh>$rmsd_thresh</rmsd_thresh>
   <min_f_dme>$minFragDME</min_f_dme>
   <max_n>$maxItNum</max_n>
   <jobfolder>$jobfolder</jobfolder>
   <add_to_calc>$add_to_calc</add_to_calc>
 </params>

 <results>
";
    if ( -d $modeldir ) {
      #    print "Directory $modeldir exists. Adding new models.\n";
    }
    else {
        if ( !mkdir( "$modeldir", 0777 ) ) {
            bad_exit("Fail create modeldir ($modeldir): $!");
        }
    }
    my $p1 = coord_name($coord1);

    print STDERR " TODO: $todo merge_alignments............\n";
    my $veclist = initveclist($todo+1);
    my $seqlist = initseqlist($todo+1);
    print STDERR "initlist done \n";
    $PVEC_STRCT_DIR = $PVEC_STRCT_DIR;
    my $pvec1;
    if ($function == 2 || $function == 0) {
        #XXX todo: use both vectors 
        $pvec1 = $pvec1_strct;
    } 
    if ($function == 1){
        $pvec1 = $pvec1_ca;
    } 
    addvec($veclist, prob_vec_read("$PVEC_STRCT_DIR/$$structlist[$indices[0]].vec"));
    my $seq = coord_get_seq(
                          coord_read(
#                                 get_path( @$struct_dirs, $$structlist[$indices[0]] . $BIN_SUFFIX ))); 
                                  get_path( @$struct_dirs, $$structlist[$indices[0]] . $BIN_SUFFIX ))); #Iryna
    addseq($seqlist, $seq);
    addvec($veclist, $pvec1);             #add the query sequence's vector
    addseq($seqlist, coord_get_seq($coord1));
    print STDERR "addvec done todo = $todo \n"; 
    my $malignm = $r::r[$indices[0]][7];
    for (my $i = 1 ; $i < $todo ; $i++ ) {
       addvec($veclist, prob_vec_read("$PVEC_STRCT_DIR/$$structlist[$indices[$i]].vec"));
       $seq = coord_get_seq(
                          coord_read(
#                                 get_path( @$struct_dirs, $$structlist[$indices[$i]] . $BIN_SUFFIX )));
                                  get_path( @$struct_dirs, $$structlist[$indices[$i]] . $BIN_SUFFIX )));
       addseq($seqlist, $seq);
    
       
       $malignm = merge_localigns($malignm, $r::r[$indices[$i]][7], 1, 1);
       $malignm = remove_seq($malignm, get_pair_set_m($malignm)-1);
    }
    my $test = get_pair_set_m($malignm);  #test

    print STDERR "m = $test \n";
    print STDERR "str X = ", pair_set_string($malignm, coord_get_seq($coord1), coord_get_seq($coord1));
    print STDERR "pair_set_stringI \n";
    print STDERR  pair_set_stringI($malignm, 1, $queryseq), "\n";
    #conservierung computing
    print STDERR "getconservvec \n";
    my $conservs = getconservvec($malignm, $veclist);
    print STDERR "get_seq_conserv \n";
    my $seqconserv = get_seq_conserv($malignm, $seqlist);
    # ====================================
    my $j = 0;
    my $shift = 0;
MINFRAGDME: { #for the dme thresh
    for (my $i = 0 ; $i < ($todo + $shift); $i++ ) {
        my $idx      = $indices[$i];
        my $pair_set = $r::r[$idx][7];
        my $a        = $r::r[$idx];

        if ($$a[9] < $minFragDME) {
           if (@$structlist < ($todo + $shift)) {
              last;
           } else {
              $shift++;
              next; #MINFRAGDME;
           }   
        }        

        my $coord2   =
        coord_read(
#             get_path( @$struct_dirs, $$structlist[$idx] . $BIN_SUFFIX ) );
              get_path( @$struct_dirs, $$structlist[$idx] . $BIN_SUFFIX ) ); #Iryna

        ($$a[1], $$a[10], my $crap_b ) =
          coord_rmsd( $$a[7], $coord2, $coord1, 0 );
        my $p2 = $$structlist[$idx];
        my $sid;
        if ( $$a[6] != 0 ) {
            $sid = $$a[4] / $$a[6];
            $sid *= 100;
        }
        else {
            $sid = 0.0;
        }
          my $pdbid=$$structlist[$idx];
        print STDERR "START START START   \n";
        my $coord2   =  coord_read(
#             get_path( @$struct_dirs, $$structlist[$idx] . $BIN_SUFFIX ) );
            get_path( @$struct_dirs, $$structlist[$idx] . $BIN_SUFFIX ) );

        my $alistr;
           my $seq1 = coord_get_seq($coord1);
           my $seq2 = coord_get_seq($coord2);
           my $testbitset = pair_set_sel_geti($pair_set);
           my $set_alg_tmp = selected_pair_set_get($pair_set, $testbitset);
           ($$a[1], $$a[10], my $coord11) = coord_rmsd( $set_alg_tmp, $$a[10], $coord1, 0);
           my $n = get_pair_set_n($set_alg_tmp);
           while ( ($$a[1] > $rmsd_thresh) && ($n > $MAG_NUM_ASREST)) {
                ($$a[1], $$a[10], my $coord11) = coord_rmsd( $set_alg_tmp, $$a[10], $coord11, 0);
                $testbitset = pair_set_sel_delmaxdistance($$a[10], $coord11, $pair_set, $testbitset);
    		$set_alg_tmp = selected_pair_set_get($pair_set, $testbitset); 
    		$n = get_pair_set_n($set_alg_tmp);
           }
        my $pdbi = $pdbid;
        $pdbi =~ s/(.*?)(.)$/$1/;

# XXX RESULT XXX
        printf XML "   
  <result id='$pdbid'>
    <pdbid>$pdbid</pdbid>
    <z_scr>%8.3g</z_scr>         
    <f_dme>%8.3g</f_dme>
    <sw_cvr>%6.2f</sw_cvr>
    <seq_id>%.0f</seq_id>
    <asize>%8.4g</asize>
    <rmsd>%6.2f</rmsd>
    <q_scr>%4.4f</q_scr>
  </result>
" ,$$a[8], $$a[9], $$a[6]/seq_size(coord_get_seq($coord1)), $sid, $$a[6], $$a[1], $$a[2];    

        my $alistr1 = pair_set_stringI($pair_set, 1, $seq1);
        my $alistr2 = pair_set_stringI($pair_set, 0, $seq2);
        my $num1 = pair_set_get_strNum($pair_set, 1, $coord1);
        my $num2 = pair_set_get_strNum($pair_set, 0, $coord2);
        my $used = pair_set_sel_print($testbitset, get_pair_set_n($pair_set));
        my $sp1 = pair_set_get_startpos($pair_set, 1);
        my $sp2 = pair_set_get_startpos($pair_set, 0);
        my $conserv;
        my $strc;
        if ($i < 1) {
          $conserv = printconserv($conservs, get_pair_set_n($malignm), $malignm, $sp1, get_pair_set_n($pair_set), $j);
          $strc = printconserv($seqconserv, get_pair_set_n($malignm), $malignm, $sp1, get_pair_set_n($pair_set), $j);
        } else {
          $conserv = printconserv($conservs, get_pair_set_n($malignm), $malignm, $sp1, get_pair_set_n($pair_set), $j+1);
          $strc = printconserv($seqconserv, get_pair_set_n($malignm), $malignm, $sp1, get_pair_set_n($pair_set), $j+1);
        }
        $j++;
        print STDERR "$strc \n";
	print STDERR pair_set_pretty_string($pair_set, $seq2, $seq1);
	open ALI, ">$htmldir/json/$$structlist[$idx].json";
        print ALI "{
    \"chains\" : {
        \"$$structlist[$idx]\" : \"$alistr2\",
        \"$vecname\" : \"$alistr1\"
    },
    \"$$structlist[$idx]_positions\" : 
    [$num2],
    \"".$vecname."_positions\" :
    [$num1],
    \"$$structlist[$idx]_startpos\" :  
    $sp1,
    \"".$vecname."\_startpos\" : 
    $sp2,
    \"conservation\" :
    [$conserv],
    \"seq_conservation\" :
    [$strc],
    \"used\" : 
    \"$used\"
}";
        coord_2_pdb("$htmldir/modeldir/$$structlist[$idx].pdb", $$a[10]);
    }
} #minFragDME:
    print "\n";
    print XML"  </results> 
 </query>";
    close XML;
    close ALI;
    
    if($N_MODELS > 0){
#	print "writing models to $modeldir";
        coord_2_pdb("$vecname.pdb", $coord1);
        for (my $i = 0 ; $i < $N_MODELS && $i < $todo ; $i++ ) {
            my $idx = $indices[$i];
            my $a = $r::r[$idx];
            coord_2_pdb("$modeldir/$$structlist[$idx].pdb", $$a[10]);
        }
    }
    undef(@r::r);
#    print "scp -r $htmldir tmargraf\@cardigan:public_html/salami/\n";
    print STDERR "htmldir=$htmldir \n OUTURL=$OUTURL \n htmlbase=$htmlbase \n RESDIR=$RESDIR \n url=$url";
    
    
    # *+-* COPYING TO FLENSBURG
    
    my $foo = `scp -B -r $htmldir/* wurst\@flensburg:$OUTURL/$jobfolder`;
    print STDERR $foo;
#    my $foo = `ssh -qx wurst\@flensburg chmod 777 $OUTURL/$htmlbase`;
#    print STDERR $foo;
#    print "$url\n";
    return EXIT_SUCCESS;
}

# ----------------------- catch_kill     ----------------------------
# The main thing is, if we get a KILL or TERM, to call exit and get
# out of here. This means there is a better chance of closing files
# wherever we were up to.
sub catch_kill
{
    my ($sig) = @_;
    bad_exit ("signal $sig received");

}

# ----------------------- kill_handlers  ----------------------------
# set up signal catchers so we can call exit() and die gracefully.
sub kill_handlers ()
{
    $SIG{INT } = \&catch_kill;
    $SIG{QUIT} = \&catch_kill;
    $SIG{TERM} = \&catch_kill;
}

# ----------------------- restore_handlers --------------------------
# If we are at the stage of mailing, we no longer want to trap
# interrupts. Otherwise, they will call the bad_exit routine again.
sub restore_handlers ()
{
    $SIG{INT } = 'DEFAULT';
    $SIG{QUIT} = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';
}

# ----------------------- reduce_priority ---------------------------
# We can reduce our own priority to be sociable.
sub reduce_priority ()
{
    my $PRIO_PGRP = 1;
    my $low_priority = 2;      # 0 is normal. 10 is very low.
    setpriority ($PRIO_PGRP, getpgrp (0), $low_priority);
}


# ----------------------- mymain  -----------------------------------
# Arg 1 is a structure file. Arg 2 is a structure list file.
sub mymain () {
    use Getopt::Std;
    my (%opts);
    my ( @struct_list, @struct_dirs );
    my ( $structfile,  $libfile );
    my $fatalflag = undef;
    @struct_dirs = @DFLT_STRUCT_DIRS;
    my $max_attach = $DFLT_MAX_ATTACH;

#--------------------------------server stuff-------------------------


#   Set up directory for output and models. It is the only place
#   we will be allowed to write to, so cleanup is easy after disaster

    if ( ! -d $TOP_TEMP ) {
        mkdir ($TOP_TEMP) || bad_exit ("Fail creating $TOP_TEMP: $!");     }
    if ( ! chdir ($TOP_TEMP)) {
        bad_exit ("Failed to cd to $TOP_TEMP: $!"); }
    use File::Temp qw (tempdir);

    # *+-* TEMPDIR AT $TOP_TEMP ON CLUSTER AT  home/other/wurst/wurst_delete.... 

#     $tmp_dir  = tempdir (DIR => $TOP_TEMP,  CLEANUP => 0);
    $tmp_dir  = tempdir (DIR => $TOP_TEMP,  CLEANUP => 0); #Iryna
    chmod 0777, $tmp_dir; # So normal people can look for disasters.
    $modeldir = "$tmp_dir/modeldir"; # Where models go. Automatically cleaned.
#   If the machines get rebooted or jobs are killed, try to mail
#   back some information. Trap the errors.
    kill_handlers();
    if ( $redirect_io ) {
#       Before doing anything, fix up stderr, stdout.
        open my $oldout, ">&STDOUT" || bad_exit ("dup stdout");
        open my $olderr, ">&STDERR" || bad_exit ("dup stderr");
        open (STDOUT, ">$tmp_dir/tempout")|| bad_exit ("redirect stdout fail");
        #       open (STDERR, ">&STDOUT")         || bad_exit ("redirect stderr fail");
        close $oldout || bad_exit ("close fail on stdout");
        close $olderr || bad_exit ("close fail on stderr");
#       From here on, any print statements, to stderr or stdout will
#       go to '$tmp_dir/tempout' in the temporary directory.
    }

    my $formatflag;
    my $email_address = "Anonymous";
    my $minFragDME;
    my $maxItNum;
    my $rmsd_t;
    my $jobfolder;
    my $add_to_calc;
#-----------------------------end server stuff------------------------

    if ( !getopts( 'a:d:e:n:h:s:t:q:l:r:f:i:o:x:p:', \%opts ) ) {
        usage();
    }
    if ( defined( $opts{a} ) ) { $N_ALIGNMENTS = $opts{a} }
    if ( defined( $opts{d} ) ) { $modeldir     = $opts{d} }
    if ( defined( $opts{o} ) ) { $jobfolder    = $opts{o} }
    if ( defined( $opts{h} ) ) { $N_BRIEF_LIST = $opts{h} }
    if ( defined( $opts{s} ) ) { $N_MODELS     = $opts{s} }
    if ( defined( $opts{e} ) ) { $email_address= $opts{e} }
    if ( defined( $opts{n} ) ) { $title	       = $opts{n} }
    if ( defined( $opts{x} ) ) { $add_to_calc  = $opts{x} }
    if ( defined( $opts{q} ) ) { $structfile   = $opts{q} }
    else{
        print STDERR "Must have at least a query structure file\n";
        usage();
    }
    if ( defined( $opts{l} ) ) { $libfile      = $opts{l} }
    else{
        print STDERR "Please give me a structure library / file\n";
        usage();
    }
    if ( defined( $opts{t} ) ) {
        push( @struct_dirs, split( ',', $opts{t} ) );
    }
    if ( defined( $opts{r} ) ) { $rmsd_t       = $opts{r} }
    if ( defined( $opts{f} ) ) { $minFragDME   = $opts{f} }
    if ( defined( $opts{i} ) ) { $maxItNum     = $opts{i} }
    # new and old vectors (smallfiles))
    if ( defined( $opts{p} ) ) {
      if ($opts{p} eq 'ca' ) {
        $function = 1;
        # change parameters to best ca parameters
        # 2902 set: -0.698265545936722 with..
        $sw1_pgap_open = $sw1_qgap_open = 2.421;
        $sw1_pgap_widen = $sw1_qgap_widen = 1.133;
        $s_factor = -0.001941;
        $s_const = 0.02312;
      } elsif ($opts{p} eq 'str') {
        $function  = 2;
        # I used Andrews o.336, best for monsterset
        $sw1_pgap_open = $sw1_qgap_open = 1.07;
        $sw1_pgap_widen = $sw1_qgap_widen = 0.855;
        $m_shift = -0.885;
        $m_s_scale = -0.4501;
      } else {
        print STDERR "I dont know this function, try ca/str\n\n";
        usage();
      }
    }
    undef %opts;
    log_job ($email_address, 'start', $title);
    if ( $max_attach > $N_MODELS ) { $max_attach = $N_MODELS; }
    set_params();
    my $query_struct;
    my $query_struct_name = $structfile; #$ARGV[0];

    $query_struct = pdb_read( $query_struct_name, '', '' );
    if ($query_struct == 0) {
        die "\npdb-read failed. ($query_struct_name)\n";
    }
    $query_struct_name =~ s/\..+$//;

#    $libfile = $ARGV[1];
    my $formatflag = 'not set';
    check_dirs(@struct_dirs);
    if ( @struct_dirs == 0 ) {
        die "\nNo valid structure directory. Stopping.\n";
    }

    ( @struct_list = get_prot_list($libfile) ) || $fatalflag++;
#     check_files( @struct_dirs, @struct_list, $BIN_SUFFIX ) && $fatalflag++;
    check_files( @struct_dirs, @struct_list, $BIN_SUFFIX ) && $fatalflag++; #Iryna
    if ($fatalflag) {
        print STDERR "struct dirs were @struct_dirs\n";
    }

    if ($fatalflag) {
        print STDERR "Fatal problems\n";
        return EXIT_FAILURE;
    }

    my $r = 0;

    # *+-* THE ACTUAL CALCULATION!!!

    do_lib( @struct_list, @struct_dirs, $query_struct_name, $query_struct,
       $title, $formatflag, $rmsd_t, $minFragDME, $maxItNum, $jobfolder, $add_to_calc);
    if ( $r == EXIT_FAILURE ) {
        bad_exit('calculation broke');
    }

   print
    "____________________________________________________________________\n",
    "Wurst gegessen at ", scalar( localtime() ), "\n";
    my ( $user, $system, $crap, $crap2, $host );
    ( $user, $system, $crap, $crap2 ) = times();
    printf "I took %d:%2d min user and %2d:%2d min sys time\n", $user / 60,
      $user % 60, $system / 60, $system % 60;
    use Sys::Hostname;
    $host = hostname() || { $host = 'no_host' };
    print "Run on $host\n\n";
    if($email_address ne "Anonymous"){
        my $subject = "$title";
        close_up_and_mail ($subject, $email_address, $max_attach);
    }
    log_job ($email_address, 'stop', $title);
    sleep 25; # Yuk, but I am so worried about the mailer.
    if ( -f "$tmp_dir/tempout" ) {
        unlink ("$tmp_dir/tempout"); }
    return EXIT_SUCCESS;
}

# ----------------------- main    -----------------------------------
exit( mymain() );
