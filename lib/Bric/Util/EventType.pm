package Bric::Util::EventType;

=head1 NAME

Bric::Util::EventType - Interface to Types of Events

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:54 $

=head1 SYNOPSIS

  # Constructors
  my $et = Bric::Util::EventType->lookup({name => 'Story Published'});
  my @ets = Bric::Util::EventType->list($params);

  # Class Methods.
  my @et_ids = Bric::Util::EventType->list_ids($params);
  my $trig_meths = Bric::Util::EventType->my_trig_meths;

  # Instance Methods
  my $id = $et->get_id;
  my $key_name = $et->get_key_name;
  my $name = $et->get_name;
  my $desc = $et->get_description;
  my $class = $et->get_class;
  my @attr = $et->get_attr;
  $et = $ae->activate;
  $et = $ae->deactivate;
  $et = $ae->is_active;
  my $event = $et->log_event($user, $obj);

=head1 DESCRIPTION

Bric::Util::EventType is designed to be the interface to the different types of
events Bricolage. New events cannot be created; they are defined ahead of time
in the database. Thus, the primary purpose of this class is to offer up a list
of events for which alerts can be set by Bric::Util::AlertType. Internally, it
can be used by the Bricolage APIs to log individual events.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
#use Bric::Util::DBI qw(:standard);
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Grp::Event;
use Bric::Biz::Person::User;
use Bric::Util::Fault::Exception::DP;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_grp, $make_obj);

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
my @cols = qw(t.id t.key_name t.name t.description c.pkg_name t.active a.id
	      a.name);

my @props = qw(id key_name name description class _active attr);
my ($meths, $trig_meths, @trig_ord, @trig_props);
my @ord = qw(key_name name description class active);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 class => Bric::FIELD_READ,
			 key_name => Bric::FIELD_READ,
			 name => Bric::FIELD_READ,
			 description => Bric::FIELD_READ,
			 attr => Bric::FIELD_READ,

			 # Private Fields
			 _active => Bric::FIELD_NONE,
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $et = Bric::Util::EventType->lookup({id => $et_id})

=item my $et = Bric::Util::EventType->lookup({key_name => $key_name})

Looks up and instantiates a new Bric::Util::EventType object based on a
Bric::Util::EventType object ID or name. If the existing object is not found in
the database, lookup() returns undef.

B<Throws:>

=over 4

=item *

Too many Bric::Util::EventType objects found.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> If $id or $key_name is found, populates the new
Bric::Util::EventType object with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $et = &$get_em(@_);
    # We want @$et to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Util::EventType objects found.' }) if @$et > 1;
    return @$et ? $et->[0] : undef;
}

################################################################################

=item my (@ets || $ets_aref) = Bric::Util::EventType->list($params)

Returns a list or anonymous array of Bric::Util::EventType objects based on the
search parameters passed via a hashref. The supported lookup keys are:

=over 4

=item *

name

=item *

description

=item *

class

=item *

class_id

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> Populates each Bric::Util::EventType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }


################################################################################

=back 4

=head2 Destructors

=over 4

=item $p->DESTROY

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

=item my (@et_ids || $et_ids_aref) = Bric::Util::EventType->list_ids($params)

Returns a list or anonymous array of Bric::Util::EventType object IDs based on the
search parameters passed via anonymous hash. The search parameters are the same
as those for list() above.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item my (@classes || $classes_aref) = Bric::Util::EventType->list_classes()

Returns a list or an anonymous array of anonymous arrays of Bricolage classes for which
types of events have been defined in the database. The each array ref in the
list contains two values: the first is the ID of the class, and the second is
its display name.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_classes {
    my $sel = prepare_c(qq{
        SELECT id, disp_name
        FROM   class
        WHERE  id in (
                   SELECT class__id
                   FROM   event_type
               )
        ORDER BY disp_name
    });

    execute($sel);
    my ($id, $dis, @ret);
    bind_columns($sel, \$id, \$dis);
    while (fetch($sel)) { push @ret, [ $id, $dis ] }
    finish($sel);
    return wantarray ? @ret : \@ret;
} # sub list_classes()

################################################################################

=item $meths = Bric::Util::EventType->my_meths

=item (@meths || $meths_aref) = Bric::Util::EventType->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item *

type - The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
	      key_name      => {
			     name     => 'key_name',
			     get_meth => sub { shift->get_key_name(@_) },
			     get_args => [],
			     disp     => 'Key Name',
			     search   => 1,
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			    },
	      name      => {
			     name     => 'name',
			     get_meth => sub { shift->get_name(@_) },
			     get_args => [],
			     disp     => 'Name',
			     search   => 1,
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			    },
	      description      => {
			     name     => 'description',
			     get_meth => sub { shift->get_description(@_) },
			     get_args => [],
			     disp     => 'Description',
			     len      => 256,
			     req      => 0,
			     type     => 'short',
			    },
	      class => {
			     name     => 'class',
			     get_meth => sub { shift->get_event_type_id(@_) },
			     get_args => [],
			     disp     => 'Class',
			     len      => 10,
			     req      => 1,
			     type     => 'short',
			    },
	      active     => {
			     name     => 'active',
			     get_meth => sub { shift->is_active(@_) ? 1 : 0 },
			     get_args => [],
			     disp     => 'Active',
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			    },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my $meths = Bric::Util::EventType->my_trig_meths

=item my @meths = Bric::Util::EventType->my_trig_meths(1)

Functions similarly to the my_meths() method on most business objects, except
that it returns that metadata for accessing data on users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_trig_meths {
    my ($pkg, $ord) = @_;
    unless ( $trig_meths) {
	foreach my $m (Bric::Biz::Person::User->my_meths(1)) {
	    my $key = "trig_$m->{name}";
	    push @trig_ord, $key;
	    push @trig_props, [$key => "Trig's $m->{disp}"];
	    $trig_meths->{$key} = $m;
	}
    }
    return !$ord ? $trig_meths : wantarray ? @{$trig_meths}{@trig_ord}
      : [@{$trig_meths}{@trig_ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $et->get_id

Returns the event type object ID.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $key_name = $et->get_key_name

Returns the event type key name.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'key_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $name = $et->get_name

Returns the event type name.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $et->get_description

Returns the event type description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $class = $et->get_class

Returns name of the class of object for which events of this type may be logged.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'class' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $attr_href = $et->get_attr

Returns an anonymous hash of the attributes required of Bric::Util::Event objects
of this Bric::Util::EventType type. The keys are the attribute names and the
values are the default values.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::Grp::Event objects found.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> Uses Bric::Util::Grp::Event internally.

B<Notes:> NONE.

################################################################################

=item $self = $et->is_active

Returns $self if the Bric::Util::EventType object is active, and undef if it is
not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

################################################################################

=item my $event =  $et->log_event($user, $obj)

=item my $event =  $et->log_event($user, $obj, $ettr)

A shortcut to Bric::Util::Event->new(). Pass in a Bric::Biz::Person::User object and
an object of the type defined by get_class(), along with any attribute/value
pairs, and a new event of this type will be logged for the object passed. Note
that not all attributes need to be explicitly passed in order to log a new
event. Any that can be called via a get_ accessor on $obj, where the method
combines 'get_' with an attribute's name, will automatically call that accessor.

See Bric::Util::Event for more information and for details on how it expects
arugments to be passed.

B<Throws:>

=over 4

=item *

No Bric::Util::EventType object, ID, or name passed to Bric::Util::Event::new().

=item *

Too many Bric::Util::EventType objects found.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bric::Util::Event::new() expects an object of type $class.

=item *

No Bric::Biz::Person::User object passed to Bric::Util::Event::new().

=back

B<Side Effects:> Uses Bric::Util::Event->new() internally.

B<Notes:> NONE.

=cut

sub log_event {
    my ($self, $user, $obj, $attr) = @_;
    Bric::Util::Event->new({ et => $self, obj => $obj, init => $attr,
			   user => $user });
}

################################################################################

=item my (@props || $props_aref) = $et->get_alert_props

Returns a list or anonymous arry of anonymous arrays that define properties that
a user can use to refine which events of a specific type will trigger alerts.
Each anonymous array within the list of alert properties contains two values.
The first is the name of the property, and the second is the display name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_alert_props {
    my $self = shift;
    $self->my_trig_meths() unless @trig_props;
    my @props = @trig_props;
    my $class = $self->_get('class');
    my $disp = Bric::Util::Class->lookup({ pkg_name => $class })->get_disp_name;
    push @props, map { [ $_->{name} => "$disp $_->{disp}" ] }
      $class->my_meths(1);
    push @props, map {
	(my $v = lc $_) =~ s/\W+/_/g;
	[ lc $v => $_ ]
    } values % { $self->_get('attr') };
    return wantarray ? @props : \@props;
}

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $event_types_aref = &$get_em( $pkg, $params )

=item my $event_types_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::EventType
objects or, if called with an optional third argument, returns a listof
Bric::Util::EventType object IDs (used by list_ids()).

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'id') {
	    push @wheres, "t.$k = ?";
	    push @params, $v;
	} elsif ($k eq 'class_id') {
	    push @wheres, "t.class__id = ?";
	    push @params, $v;
	} elsif ($k eq 'class') {
	    push @wheres, "LOWER(c.pkg_name) LIKE ?";
	    push @params, lc $v;
	} else {
	    push @wheres, "LOWER(t.$k) LIKE ?";
	    push @params, lc $v;
	}
    }

    my $where = defined $params->{id} ? '' : 'AND t.active = 1 ';
    local $" = ' AND ';
    $where .= "AND @wheres" if @wheres;

    local $" = ', ';
    my $qry_cols = $ids ? ['DISTINCT t.id'] : \@cols;
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   event_type t LEFT JOIN event_type_attr a ON t.id = a.event_type__id,
               class c
        WHERE  c.id = t.class__id
               $where
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my ($last, @d, @init, $aid, $aname, @ets) = (-1);
    bind_columns($sel, \@d[0..$#props - 1], \$aid, \$aname);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	if ($d[0] != $last) {
	    # Create a new object.
	    push @ets, &$make_obj($pkg, \@init) unless $last == -1;
	    # Get the new record.
	    $last = $d[0];
	    @init = (@d, {});
	}
	# Grab any attributes.
	$init[$#init]->{$aid} = $aname if $aid;
    }
    # Grab the last object.
    push @ets, &$make_obj($pkg, \@init) if @init;
    # Return the objects.
    return \@ets;
};

################################################################################]

=item my $et = &$make_obj( $pkg, $init )

Instantiates a Bric::Util::EventType object. Used by &$get_em().

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_obj = sub {
    my ($pkg, $init) = @_;
    my $self = bless {}, $pkg;
    $self->SUPER::new;
    $self->_set(\@props, $init);
};

1;
__END__

=back

=head1 NOTES

This is an early draft of this class, and therefore subject to change.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Util::Event(4)
Bric::Util::AlertType(5)
Bric::Util::Alert(6)

=cut

