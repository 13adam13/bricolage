package Bric::Util::Grp::Keyword;

=head1 NAME

Bric::Util::Grp::Keyword - Interface to Bric::Biz::Keyword Groups

=head1 VITALS

=over 4

=item Version

$Revision: 1.10 $

=cut

# Grab the Version Number.
use Bric; our $VERSION = Bric->VERSION;

=item Date

$Date: 2003/03/30 18:34:20 $

=item CVS ID

$Id: Keyword.pm,v 1.10 2003/03/30 18:34:20 wheeler Exp $

=back

=head1 SYNOPSIS

See Bric::Util::Grp

=head1 DESCRIPTION

See Bric::Util::Grp.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
# None.

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric::Util::Grp);

##############################################################################
# Function Prototypes
##############################################################################
# None.

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant OBJ_CLASS_ID => 41;
use constant CLASS_ID => 28;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields
my ($CLASS, $MEM_CLASS);

##############################################################################

##############################################################################
# Instance Fields
BEGIN { Bric::register_fields() }

##############################################################################
# Class Methods
##############################################################################

=head1 INTERFACE

=head2 Constructors

Inherited from Bric::Util::Grp.

=head2 Class Methods

=head3 get_supported_classes

  my $supported_classes = Bric::Util::Grp::Keyword->get_supported_classes;

This will return an anonymous hash of the supported classes in the group as
keys with the short name as a value. The short name is used to construct the
member table names and the foreign key in the table.

=cut

sub get_supported_classes { { 'Bric::Biz::Keyword' => 'keyword' } }

##############################################################################

=head3 get_object_class_id

 my $class_id = Bric::Util::Grp::Keyword->get_object_class_id;

If this method returns an ID, then all objects returne as members of this
class of group will be instances of the class represented by that ID. If no ID
is returned, then member objects will not be forced into the single class.

=cut

sub get_object_class_id { OBJ_CLASS_ID }

##############################################################################

=head3 get_class_id

  my $class_id = Bric::Util::Grp::Keyword->get_class_id;

Returns the Bric::Util::Class object ID representing this class.

=cut

sub get_class_id { CLASS_ID }

##############################################################################

=head3 get_secret

  my $secret = Bric::Util::Grp::Keyword->get_secret;

Returns false, because groups of this class are not secret groups, but groups
that can be used by users.

=cut

sub get_secret { 0 }

##############################################################################

=head3 my_class

  my $class = Bric::Util::Grp::Keyword->my_class;

Returns the Bric::Util::Class object representing this class.

=cut

sub my_class {
    $CLASS ||= Bric::Util::Class->lookup({ id => CLASS_ID });
    return $CLASS;
}

##############################################################################

=head3 member_class

  my $class = Bric::Util::Grp::Keyword->member_class;

Returns the Bric::Util::Class object representing the members of this group.

=cut

sub member_class {
    $MEM_CLASS ||= Bric::Util::Class->lookup({ id => OBJ_CLASS_ID });
    return $MEM_CLASS;
}

##############################################################################

=head2 Instance Methods

Inherited from Bric::Util::Grp.

=cut

1;
__END__

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

=over 4

=item L<Bric::Util::Grp|Bric::Util::Grp>

=item L<Bric::Biz::Keyword|Bric::Biz::Keyword>

=back

=cut
