#!/usr/bin/perl -w

=head1 NAME

files.pl - installation script to create directories and copy files

=head1 VERSION

$Revision: 1.7 $

=head1 DATE

$Date: 2003-04-15 09:04:58 $

=head1 DESCRIPTION

This script is called during "make install" to create Bricolage's
directories, copy files and setup permissions.

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
use File::Path qw(mkpath rmtree);
use File::Find qw(find);
use File::Copy qw(copy);

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user? [yes] ", 1);
}

print "\n\n==> Copying Bricolage Files <==\n\n";

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $AP;
do "./apache.db" or die "Failed to read apache.db : $!";

# check if we're upgrading
our $UPGRADE;
$UPGRADE = 1 if $ARGV[0] and $ARGV[0] eq 'UPGRADE';

create_paths();

# Remove old object files if this is an upgrade.
rmtree(catdir $CONFIG->{MASON_DATA_ROOT}, 'obj' ) if $UPGRADE;

# Copy the Mason UI components.
find({ wanted   => sub { copy_files($CONFIG->{MASON_COMP_ROOT}) },
       no_chdir => 1 }, './comp');

# Copy the contents of the bconf directory.
find({ wanted   => sub { copy_files(catdir $CONFIG->{BRICOLAGE_ROOT}, "conf") },
       no_chdir => 1 }, './bconf');

unless ($UPGRADE) {
    # Copy the contents of the data directory.
    find({ wanted   => sub { copy_files($CONFIG->{MASON_DATA_ROOT}) },
           no_chdir => 1 }, './data');
}

assign_permissions();


print "\n\n==> Finished Copying Bricolage Files <==\n\n";
exit 0;


# create paths configured by the user
sub create_paths {
    mkpath([catdir($CONFIG->{MASON_COMP_ROOT}, "data"),
	    $CONFIG->{MASON_DATA_ROOT},
	    catdir($CONFIG->{BRICOLAGE_ROOT}, "conf"),
	    catdir($CONFIG->{TEMP_DIR}, "bricolage"),
	    $CONFIG->{LOG_DIR}],
	   1,
	   0755);
}

# copy files - should be called by a find() with no_chdir set
sub copy_files {
    my $root = shift;
    return if /\.$/;
    return if /CVS/;
    return if /\.cvsignore$/;
    return if $UPGRADE and m!/data/!; # Don't upgrade data files.
    return if $UPGRADE and /bconf/ and /\.conf$/; # Don't upgrade .conf files.

    # construct target by lopping off ^./foo/ and appending to $root
    my $targ;
    ($targ = $_) =~ s!^\./\w+/?!!;
    return unless length $targ;
    $targ = catdir($root, $targ);

    if (-d) {
	mkpath([$targ], 1, 0755) unless -e $targ;
    } else {
	copy($_, $targ)
	    or die "Unable to copy $_ to $targ : $!";
	chmod((stat($_))[2], $targ)
	    or die "Unable to copy mode from $_ to $targ : $!";
    }
}

# assigns the proper permissions to the various directories created
# and the files beneath them.
sub assign_permissions {
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{MASON_COMP_ROOT}, "data"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   $CONFIG->{MASON_DATA_ROOT});
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{TEMP_DIR}, "bricolage"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{LOG_DIR}));
}
