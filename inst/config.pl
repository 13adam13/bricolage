#!/usr/bin/perl -w

=head1 NAME

config.pl - installation script to probe user configuration

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during "make" to ask the user questions about
their desired installation.  Output collected in "config.db".

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use Data::Dumper;
use Config;
use Cwd;

# check whether questions should be asked
our $QUIET;
$QUIET = 1 if $ARGV[0] and $ARGV[0] eq 'QUIET';

print "\n\n==> Gathering User Configuration <==\n\n";
our %CONFIG;

# our $REQ;
# do "./required.db" or die "Failed to read required.db : $!";

our $AP;
do "./apache.db" or die "Failed to read apache.db : $!";

choose_defaults();
confirm_settings();

# all done, dump out apache database, announce success and exit
open(OUT, ">config.db") or die "Unable to open config.db : $!";
print OUT Data::Dumper->Dump([\%CONFIG],['CONFIG']);
close OUT;

print "\n\n==> Finished Gathering User Configuration <==\n\n";
exit 0;

sub choose_defaults {

if (!$QUIET) {

    print <<END;
========================================================================

Bricolage comes with two sets of defaults.  You'll have the
opportunity to override these defaults but choosing wisely here will
probably save you the trouble.  Your choices are:

  s - "single"   one installation for the entire system

  m - "multi"    an installation that lives next to other installations
                 on the same machine

END

    $CONFIG{set} = "s";
    $CONFIG{set} = ask_choice("Your choice?", [ "s", "m" ], "s", $QUIET);

    # setup the default
    if ($CONFIG{set} eq 's') {
        # single system defaults
        $CONFIG{BRICOLAGE_ROOT}  = '/usr/local/bricolage';
        $CONFIG{TEMP_DIR}        = tmpdir();
        $CONFIG{MODULE_DIR}      = $Config{sitelib};
        $CONFIG{BIN_DIR}         = $Config{scriptdir};
        $CONFIG{MAN_DIR}         = $Config{man3dir};
        $CONFIG{MASON_COMP_ROOT} = '$CONFIG{BRICOLAGE_ROOT}/comp';
        $CONFIG{MASON_DATA_ROOT} = '$CONFIG{BRICOLAGE_ROOT}/data';

        # remove man3 trailer
        $CONFIG{MAN_DIR} =~ s!/man3!!;

        # construct default system-wide log directory based on Apache
        # error_log setting
        if (file_name_is_absolute($AP->{DEFAULT_ERRORLOG})) {
            $CONFIG{LOG_DIR} = (splitpath($AP->{DEFAULT_ERRORLOG}))[1];
        } else {
            $CONFIG{LOG_DIR} = (splitpath(catfile($AP->{HTTPD_ROOT},
                                                  $AP->{DEFAULT_ERRORLOG})))[1];
        }

        # construct default system-wide pid file location
        if (file_name_is_absolute($AP->{DEFAULT_PIDLOG})) {
            $CONFIG{PID_FILE} = $AP->{DEFAULT_PIDLOG};
        } else {
            $CONFIG{PID_FILE} = catfile($AP->{HTTPD_ROOT},
                                        $AP->{DEFAULT_PIDLOG});
        }

    } else {
        # multi system defaults
        $CONFIG{BRICOLAGE_ROOT}  = '/usr/local/bricolage';

        # evaluated after BRICOLAGE_ROOT is set
        $CONFIG{TEMP_DIR}         = '$CONFIG{BRICOLAGE_ROOT}/tmp';
        $CONFIG{MODULE_DIR}       = '$CONFIG{BRICOLAGE_ROOT}/lib';
        $CONFIG{BIN_DIR}          = '$CONFIG{BRICOLAGE_ROOT}/bin';
        $CONFIG{MAN_DIR}          = '$CONFIG{BRICOLAGE_ROOT}/man';
        $CONFIG{LOG_DIR}          = '$CONFIG{BRICOLAGE_ROOT}/log';
        $CONFIG{PID_FILE}         = '$CONFIG{BRICOLAGE_ROOT}/log/httpd.pid';
        $CONFIG{MASON_COMP_ROOT}  = '$CONFIG{BRICOLAGE_ROOT}/comp';
        $CONFIG{MASON_DATA_ROOT}  = '$CONFIG{BRICOLAGE_ROOT}/data';
    }
} else {
    # use QUIET defaults
    $CONFIG{BRICOLAGE_ROOT}   = get_default("BRICOLAGE_ROOT_DIR");
    $CONFIG{TEMP_DIR}         = get_default("BRICOLAGE_TMP_DIR");
    $CONFIG{MODULE_DIR}       = get_default("BRICOLAGE_PERL_DIR");
    $CONFIG{BIN_DIR}          = get_default("BRICOLAGE_BIN_DIR");
    $CONFIG{MAN_DIR}          = get_default("BRICOLAGE_MAN_DIR");
    $CONFIG{LOG_DIR}          = get_default("BRICOLAGE_LOG_DIR");
    $CONFIG{PID_FILE}         = get_default("BRICOLAGE_PID");
    $CONFIG{MASON_COMP_ROOT}  = get_default("BRICOLAGE_COMP_DIR");
    $CONFIG{MASON_DATA_ROOT}  = get_default("BRICOLAGE_DATA_DIR");
}
}

sub confirm_settings {
  my $default_root = $CONFIG{BRICOLAGE_ROOT};
  ask_confirm("\nBricolage Root Directory", \$CONFIG{BRICOLAGE_ROOT}, $QUIET);

  # make sure this directory isn't the same at the source directory
  if (canonpath($CONFIG{BRICOLAGE_ROOT}) eq canonpath(cwd())) {
      print "\nYou cannot install Bricolage into the same directory where it ".
        "is being built.\n";
      print "Please choose another directory.\n";
      $CONFIG{BRICOLAGE_ROOT} = $default_root;
      return confirm_settings();
  }


  # make sure this directory doesn't already house a Bricolage install
  if (-e $CONFIG{BRICOLAGE_ROOT} and
      -e catfile($CONFIG{BRICOLAGE_ROOT}, "conf", "bricolage.conf")) {
      print "That directory already contains a Bricolage installation.\n";
      print "Consider running `make upgrade`, instead.\n";
      exit 1 unless ask_yesno("Continue and overwrite existing installation? ".
                              "[no] ", 0);
  }

  # some prefs are based on BRICOLAGE_ROOT, need to eval them now
  foreach (qw(TEMP_DIR MODULE_DIR BIN_DIR MAN_DIR LOG_DIR PID_FILE
              MASON_COMP_ROOT MASON_DATA_ROOT)) {
    $CONFIG{$_} = eval qq{"$CONFIG{$_}"};
  }

  ask_confirm("Temporary Directory",       \$CONFIG{TEMP_DIR}, $QUIET);
  ask_confirm("Perl Module Directory",     \$CONFIG{MODULE_DIR}, $QUIET);
  ask_confirm("Executable Directory",      \$CONFIG{BIN_DIR}, $QUIET);
  ask_confirm("Man-Page Directory (! to skip)", \$CONFIG{MAN_DIR}, $QUIET);
  ask_confirm("Log Directory",             \$CONFIG{LOG_DIR}, $QUIET);
  ask_confirm("PID File Location",         \$CONFIG{PID_FILE}, $QUIET);
  ask_confirm("Mason Component Directory", \$CONFIG{MASON_COMP_ROOT}, $QUIET);
  ask_confirm("Mason Data Directory",      \$CONFIG{MASON_DATA_ROOT}, $QUIET);

  $CONFIG{PID_FILE} = catfile($CONFIG{PID_FILE}, 'httpd.pid')
    if -d $CONFIG{PID_FILE};
}
