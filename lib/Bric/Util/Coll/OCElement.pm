package Bric::Util::Coll::OCElement;
###############################################################################

=head1 NAME

Bric::Util::Coll::OCElement - Interface for managing collections of
Bric::Biz::OutputChannel::Element objects.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-09-18 19:57:25 $

=head1 SYNOPSIS

See Bric::Util::Coll.

=head1 DESCRIPTION

See Bric::Util::Coll.

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
use base qw(Bric::Util::Coll);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields
BEGIN { }

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

Inherited from Bric::Util::Coll.

=head2 Destructors

=over 4

=item $org->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item Bric::Util::Coll->class_name()

Returns the name of the class of objects this collection manages.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub class_name { 'Bric::Biz::OutputChannel::Element' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

Saves the changes made to all the objects in the collection

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    # Save the deleted objects.
    foreach my $oce (@$del_objs) {
        if ($oce->get_id) {
            $oce->remove;
            $oce->save;
        }
    }
    @$del_objs = ();

    # Save the existing and new objects.
    foreach my $oce (values %$objs, @$new_objs) {
	$oce->save;
    }

    # Add the new objects to the main list of objects.
    $self->add_objs(@$new_objs);

    # Reset the new_objs array and return.
    @$new_objs = ();
    return $self;
}

=back

=head1 PRIVATE

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
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::OutputChannel::Element|Bric::Biz::OutputChannel::Element>

=cut
