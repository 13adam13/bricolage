#!/usr/bin/perl -w

=head1 NAME

clone.pl - installation script to copy files for clone distributions

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2002-08-13 22:05:10 $

=head1 DESCRIPTION

This script is called by "make clone" to build the tar ball with the
desired name.

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

our $CLONE;
do "./clone.db" or die "Failed to read clone.db : $!";

print "\n\n==> Creating Cloning Tar Ball <==\n\n";

# build the clone tar file
system(qq(mv dist "bricolage-$CLONE->{NAME}"));
system(qq(tar cvf "bricolage-$CLONE->{NAME}.tar" "bricolage-$CLONE->{NAME}"));
system(qq(gzip --best "bricolage-$CLONE->{NAME}.tar"));

print "\n\n==> Finished Creating Cloning Tar Ball <==\n\n";
