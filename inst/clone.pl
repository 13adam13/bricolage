#!/usr/bin/perl -w

=head1 NAME

clone.pl - installation script to gather clone information

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2004-02-11 06:46:26 $

=head1 DESCRIPTION

This script is called by "make clone" to prepare for building a cloned
distribution.  Gathers configuration information from the user and
install.db if available.  Outputs to the various .db files used by
later stages of the install.

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

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user? [yes] ", 1);
}

# setup default root
our %CLONE = ( BRICOLAGE_ROOT => $ENV{BRICOLAGE_ROOT} ||
               '/usr/local/bricolage' );
our ($INSTALL, $VERSION);

# determine version being installed
use lib './lib';

eval find_version();

print "\n\n==> Setting-up Bricolage $VERSION Clone Process <==\n\n";

get_bricolage_root();
read_install_db();
check_version();
confirm_paths();
get_clone_name();
output_dbs();

print "\n\n==> Finished Setting-up Bricolage Clone Process <==\n\n";

# find_version
sub find_version {
    my $bric = catfile $FindBin::Bin, updir, 'lib', 'Bric.pm';
    open BRIC, $bric or die "Cannot open $bric: $!\n";
    my $inpod;
    while (<BRIC>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        return $_ if m/([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
    }
    return;
}

# get clone name
sub get_clone_name {
    print "\n";
    $CLONE{NAME} = "NONE";
    ask_confirm("What would you like to name your clone ".
                "(used to name the archive)? ", \$CLONE{NAME});
}

# find the bricolage to update
sub get_bricolage_root {
    ask_confirm("Bricolage Root Directory to Clone?",
		\$CLONE{BRICOLAGE_ROOT});

    $CLONE{CONFIG_DIR} = catdir $CLONE{BRICOLAGE_ROOT}, 'conf';
    ask_confirm("Bricolage Config Directory",
		\$CLONE{CONFIG_DIR});

    # verify that we have a Bricolage install here
    hard_fail("No Bricolage installation found in $CLONE{BRICOLAGE_ROOT}.\n")
	unless -e catfile($CLONE{CONFIG_DIR}, "bricolage.conf");

    # verify that this Bricolage was installed with "make install"
    hard_fail("The Bricolage Installation found in $CLONE{BRICOLAGE_ROOT}\n",
	      "was installed manually and cannot be cloned.")
	unless -e catfile($CLONE{CONFIG_DIR}, "install.db");
}

# read the install.db file from the chosen bricolage root
sub read_install_db {
    my $install_file = catfile($CLONE{CONFIG_DIR}, "install.db");
    if (-e $install_file) {
	# read it in if it exists
	do $install_file or die "Failed to read $install_file : $!";
    }
}

# check that the version numbers match
sub check_version {
    my @todo;

    # make sure we're not cloning a different version
    if ($INSTALL->{VERSION} ne $VERSION) {
        print <<END;
The installed version ("$VERSION") is not same as this version!  "make
clone" is only designed to work with like versions.
END
        exit 1 unless ask_yesno("Continue with clone? [no] ", 0);
        @todo = ($VERSION);

    }
}

# confirm paths listed in install.db
sub confirm_paths {
    print "\nPlease confirm the Bricolage clone source directories.\n\n";
    ask_confirm("Bricolage Perl Module Directory",
		\$INSTALL->{CONFIG}{MODULE_DIR});
    ask_confirm("Bricolage Executable Directory",
		\$INSTALL->{CONFIG}{BIN_DIR});
    ask_confirm("Mason Component Directory",
		\$INSTALL->{CONFIG}{MASON_COMP_ROOT});
    ask_confirm("Mason Data Directory",
		\$INSTALL->{CONFIG}{MASON_DATA_ROOT});
}

# output .db files used by installation steps
sub output_dbs {
    # fake up the .dbs from %INSTALL
    my %dbs = ( PG     => "postgres.db",
		CONFIG => "config.db",
		AP     => "apache.db"  );
    while ( my ($key, $file) = each %dbs) {
	open(FILE, ">$file") or die "Unable to open $file : $!";
	print FILE Data::Dumper->Dump([$INSTALL->{$key}], [$key]);
	close(FILE);
    }

    # output upgrade.db
    open(FILE, ">clone.db") or die "Unable to open clone.db : $!";
    print FILE Data::Dumper->Dump([\%CLONE], ["CLONE"]);
    close(FILE);
}
