package Bric::Util::Coll::Rule;
###############################################################################

=head1 NAME

Bric::Util::Coll::Rule - Interface for managing collections of alert type rules.

=head1 VERSION

$Revision: 1.11 $

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Date: 2003/07/25 04:39:28 $

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
use Bric::Util::AlertType::Parts::Rule;

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
BEGIN {
}

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

sub class_name { 'Bric::Util::AlertType::Parts::Rule' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

Saves the changes made to all the objects in the collection.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my ($self, $atid) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    foreach my $r (values %$del_objs) {
	$r->remove;
	$r->save;
    }
    %$del_objs = ();
    foreach my $r (values %$objs, @$new_objs) {
	$r->set_alert_type_id($atid) if defined $atid;
	$r->save;
    }
    $self->add_objs(@$new_objs);
    @$new_objs = ();
    return $self;
}

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This implementation
overrides the default, using an explicit numeric sort.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return @{$objs}{sort { $a <=> $b } keys %$objs};
}

=back

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
L<Bric::Util::AlertType|Bric::Util::AlertType>,
L<Bric::Util::AlertType::Parts::Rule|Bric::Util::AlertType::Parts::Rule>

=cut
