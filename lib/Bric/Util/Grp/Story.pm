package Bric::Util::Grp::Story;

=head1 NAME

Bric::Util::Grp::Story - Interface to Bric::Biz::Asset::Business::Story Groups.

=head1 VERSION

$Revision: 1.8.2.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.8.2.1 $ )[-1];

=head1 DATE

$Date: 2003/03/15 03:59:50 $

=head1 SYNOPSIS

See Bric::Util::Grp

=head1 DESCRIPTION

See Bric::Util::Grp.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Grp);

################################################################################
# Function Prototypes
################################################################################


################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant CLASS_ID => 65;
use constant OBJECT_CLASS_ID => 10;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my ($class, $mem_class);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields();
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

Inherited from Bric::Util::Grp.

=head2 Destructors

=over 4

=item $attr->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over

=item $supported_classes = Bric::Util::Grp::Story->get_supported_classes()

This will return an anonymous hash of the supported classes in the group as keys
with the short name as a value. The short name is used to construct the member
table names and the foreign key in the table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_supported_classes { { 'Bric::Biz::Asset::Business::Story' => 'story' } }

##############################################################################

=item my @list_classes = Bric::Util::Grp::Story->get_list_classes

Returns a list or anonymous array of the supported classes in the group that
can have their C<list()> methods called in succession to assemble a list of
member objects. This data varies from that stored in the keys in the hash
reference returned by C<get_supported_classes> in that some classes' C<list()>
methods may inherit from others, and we don't want the same C<list()> method
executed more than once.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_list_classes { ('Bric::Biz::Asset::Business::Story') }

################################################################################

=item $class_id = Bric::Util::Grp::Story->get_object_class_id

Forces all Objects to be considered as this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_object_class_id { OBJECT_CLASS_ID }

################################################################################

=item $class_id = Bric::Util::Grp::Story->get_class_id()

This will return the class ID that this group is associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_class_id { CLASS_ID }

################################################################################

=item my $secret = Bric::Util::Grp::Story->get_secret()

Returns false, because this is not a secret type of group, but one that can be
used by users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { Bric::Util::Grp::NONSECRET_GRP }

################################################################################

=item my $class = Bric::Util::Grp::Story->my_class()

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => CLASS_ID });
    return $class;
}

################################################################################

=item my $class = Bric::Util::Grp::Story->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => OBJECT_CLASS_ID });
    return $mem_class;
}

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Grp.

=head1 PRIVATE

=head2 Private Constructors

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>, 
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>, 
L<Bric::Util::Grp|Bric::Util::Grp>

=cut
