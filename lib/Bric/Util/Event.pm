package Bric::Util::Event;

=head1 NAME

Bric::Util::Event - Interface to Bricolage Events

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:54 $

=head1 SYNOPSIS

  # Constructors.
  my $event = Bric::Util::Event->new($init);
  my $event = Bric::Util::Event->lookup({id => $id});
  my @events = Bric::Util::Event->list(params)

  # Class Methods.
  my @eids = Bric::Util::Event->list_ids($params)

  # Instance Methods.
  my $id = $event->get_id;
  my $et = $event->get_event_type;
  my $et_id = $event->get_event_type_id;
  my $user = $event->get_user;
  my $user_id = $event->get_user_id;
  my $obj = $event->get_obj;
  my $obj_id = $event->get_obj_id;
  my $time = $event->get_timestamp;
  my $key_name = $event->get_key_name; # Same as returned by $et.
  my $name = $event->get_name;         # Same as returned by $et.
  my $desc = $event->get_description;  # Same as returned by $et.
  my $class = $event->get_class;       # Same as returned by $et.

=head1 DESCRIPTION

Bric::Util::Event provides an interface to individual Bricolage events. It is
used primarily to create a list of events relative to a particular Bricolage
object. Events can only be de logged for a pre-specified list of event types as
defined by Bric::Util::EventType. In fact, I recommend that you use the
log_event() method on an Bric::Util::EventType object to log individual events,
rather than creating them here with the new() method. Either way, the event will
be logged and all necessary alerts defined via the Bric::Util::AlertType class
will be sent.

While the primary purpose of this class is to create lists of events, I have
provided a number of methods to make it as flexible an API as possible. These
include the ability to automatically instantiate the object for which an event
was logged, or the Bric::Biz::Person::User object representing the user who
triggered the event.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard);
use Bric::Util::Time qw(:all);
use Bric::Util::EventType;
use Bric::Util::AlertType;
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
my ($get_em, $make_obj, $save, $save_attr, $get_et);

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
my @cols = qw(e.id t.id e.usr__id e.obj_id e.timestamp t.key_name t.name
	      t.description c.pkg_name ta.name ea.value);
splice @cols, -2, 0,
  'CASE WHEN e.id in (SELECT event__id from alert) THEN 1 ELSE 0 END';

my @props = qw(id event_type_id user_id obj_id timestamp key_name name
	       description class _alert attr);

my @ecols = qw(id event_type__id usr__id obj_id timestamp);
my @eprops = qw(id event_type_id user_id obj_id timestamp);

my @ord = qw(name key_name description trig_id trig class timestamp);
my $meths;

my %num_map = (id => 'e.id = ?',
	       event_type_id => 't.id = ?',
	       user_id => 'e.usr__id = ?',
	       obj_id => 'e.obj_id = ?',
	       class_id => 't.class__id = ?');

my %txt_map = (key_name => 'LOWER(t.key_name) = ?',
	       name => 'LOWER(g.name) = ?',
	       description => 'LOWER(g.description) = ?',
	       class => 'LOWER(c.name) = ?'
	      );


################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 event_type_id => Bric::FIELD_READ,
			 user_id => Bric::FIELD_READ,
			 obj_id => Bric::FIELD_READ,
			 timestamp => Bric::FIELD_READ,
			 key_name => Bric::FIELD_READ,
			 name => Bric::FIELD_READ,
			 description => Bric::FIELD_READ,
			 class => Bric::FIELD_READ,
			 attr => Bric::FIELD_READ,

			 # Private Fields
			 _et => Bric::FIELD_NONE,
			 _alert => Bric::FIELD_READ,
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $event = Bric::Util::Event->new($init)

Instantiates and saves a Bric::Util::Event object. Returns the new event object on
success and undef on failure. An anonymous hash of initial values must be passed
with the following keys:

=over 4

=item *

et - A Bric::Util::EventType object, which defines what type of event to log. If
you happen to have already instantiated a Bric::Util::EventType object, use that
object rather than its ID to avoid creating a second instantiation of the same
object inernally.

=item *

et_id - A Bric::Util::EventType object ID. May be passed instead of et. A
Bric::Util::EventType object ID will be instantiated internally.

=item *

name - A Bric::Util::EventType object name. May be passed instead of et or et_id.
A Bric::Util::EventType object ID will be instantiated internally.

=item *

obj - The object for which the event will be logged.

=item *

user - The Bric::Biz::Person::User object representing the user who triggered the
event.

=item *

attr - An anonymous hash representing the attributes required to log the event.
All must have values or they'll throw an error.

=item *

timestamp - The event's time. Optional.

=back

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

B<Side Effects:> Creates the new event and saves it to the database.

B<Notes:> Use new() only to create a completely new event object. It will
automatically be saved before returning the new event object. Use lookup() or
list() to fetch pre-existing event objects.

In the future, attributes may not need to be passed for all attribute logging.
That is, if the attributes can be collected direct from the object of this
event via accessors, they need not be passed in via this anonymous hash. The
accessors must be named 'get_' plus the name of the attribute to be fetched
(such as 'get_slug') in order for the method-call approach to collecting
atrributes to work. But this is not yet implemented.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;

    # Make sure we've got full EventType object.
    my $et = $init->{et};
    unless ($et) {
	if (defined $init->{et_id}) {
	    $et = Bric::Util::EventType->lookup({ id => $init->{et_id} });
	} elsif ($init->{key_name}) {
	    $et = Bric::Util::EventType->lookup({ key_name => $init->{key_name} });
	} else {
	    die Bric::Util::Fault::Exception::DP->new({
              msg => "No Bric::Util::EventType object, ID, or name passed to " .
                     __PACKAGE__ . '::new()' });
	}
    }

    my ($class, $et_id) = ($et->_get('class', 'id'));
    # Die if the object we're logging against isn't in the right class.
    my $obj = $init->{obj};
    $obj->isa($class) || die Bric::Util::Fault::Exception::DP->new({
      msg => __PACKAGE__ . "::new() expects an object of type $class" });

    # Die if no user has been passed.
    my $user = $init->{user};
    $user->isa('Bric::Biz::Person::User') ||
      die Bric::Util::Fault::Exception::DP->new({
        msg => "No Bric::Biz::Person::User object passed to " .
               __PACKAGE__ . '::new()' });

    # Inititialize the standard MPS::Event properties.
    $self->SUPER::new({event_type_id => $et_id,
		       user_id       => $user->get_id,
		       obj_id        => $obj->get_id,
		       timestamp     => db_date($init->{timestamp}, 1),
		       name          => $et->get_name,
		       key_name      => $et->get_key_name,
		       description   => $et->get_description,
		       class         => $et->get_class,
		       _et           => $et
		      });

    my $id = &$save($self);             # Save this event to the database.

    # Now save any attributes.
    $self->_set(['attr'], [&$save_attr($id, $et, $init->{attr})])
      if $init->{attr};

    # Send out any alerts specified for this event.
    $init->{event} = $self;
    for my $at (Bric::Util::AlertType->list({ event_type_id => $et_id })) {
        $at->send_alerts($init);
    }
    return $self;
}

################################################################################

=item my $event = Bric::Util::Event->lookup({id => $id})

Looks up and instantiates a new Bric::Util::Event object based on the
Bric::Util::Event object ID. If the existing object is not found in the database,
lookup() returns undef. If the ID or name is found more than once, lookup()
returns zero (0). This should not happen.

B<Throws:>

=over

=item *

Too many Bric::Util::Event objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Person object with data
from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $event = &$get_em(@_);
    # We want @$event to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Util::Event objects found.' }) if @$event > 1;
    return @$event ? $event->[0] : undef;
}

################################################################################

=item my (@events || $events_aref) = Bric::Util::Event->list($params)

Returns a list of Bric::Util::Event objects based on the search parameters passed
via an anonymous hash. The supported lookup keys are:

=over 4

=item *

event_type_id

=item *

user_id

=item *

class_id

=item *

obj_id

=item *

timestamp

=back

If timestamp is passed as a scalar, events that occurred at that exact time will
be returned. If it is passed as an anonymous hash, the first two values will be
assumed to represent a range of dates between which to retrieve Bric::Util::Event
objects. Any combination of the above keys may be used, although the most common
may be a combination of class_id and obj_id.

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

B<Side Effects:> Populates each Bric::Util::Event object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item $meths = Bric::Biz::Person->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Person->my_meths(TRUE)

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
	      name      => {
			     name     => 'name',
			     get_meth => sub { shift->get_name(@_) },
			     get_args => [],
			     disp     => 'Name',
			     len      => 64,
			    },
	      description      => {
			     name     => 'description',
			     get_meth => sub { shift->get_description(@_) },
			     get_args => [],
			     disp     => 'Description',
			     len      => 256,
			    },
	      class      => {
			     name     => 'class',
			     get_meth => sub { shift->get_class(@_) },
			     get_args => [],
			     disp     => 'Class',
			     len      => 128,
			    },
	      timestamp  => {
			     name     => 'timestamp',
			     get_meth => sub { shift->get_timestamp(@_) },
			     get_args => [],
			     disp     => 'Timestamp',
			     search   => 1,
			     len      => 128,
			    },
	      user_id  => {
			     name     => 'user_id',
			     get_meth => sub { shift->get_user_id(@_) },
			     get_args => [],
			     disp     => 'Triggered By',
			     len      => 256,
			    },
	      trig  => {
			     name     => 'trig',
			     get_meth => sub { shift->get_user(@_)->get_name },
			     get_args => [],
			     disp     => 'Triggered By',
			     len      => 256,
			    },
	      attr       => {
			     name     => 'attr',
			     get_meth => sub { shift->get_attr(@_) },
			     get_args => [],
			     disp     => 'Attributes',
			     len      => 128,
			    },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

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

################################################################################

=item my (@eids || $eids_aref) = Bric::Biz::Person->list_ids($params)

Functionally identical to list(), but returns Bric::Util::Event object IDs rather
than objects. See list() for a description of its interface.

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

=head2 Public Instance Methods

=over 4

=item my $id = $event->get_id

Returns the event object ID.

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

=item my $et = $event->get_event_type

Returns the event type object defining the event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_event_type { &$get_et(shift) }

=item my $et_id = $event->get_event_type_id

Returns the ID of the event type object defining the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'event_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $u = $event->get_user

Returns the Bric::Biz::Person::User object representing the person who triggered the
event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Biz::Person::User objects found.

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

sub get_user { Bric::Biz::Person::User->lookup({ id => $_[0]->_get('user_id') }) }

=item my $uid = $event->get_user_id

Returns the ID of the Bric::Biz::Person::User object representing the person who
triggered the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'user_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $obj = $event->get_obj

Returns the object for which this event was logged. The class of the object
may be fetched from $event->get_class.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many objects found.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_obj {
    my $self = shift;
    my $class = $self->_get('class');
    return $class->lookup({ id => $self->_get('obj_id') });
}

=item my $obj_id = $event->get_obj_id

Returns the ID of the object for which this event was logged. The class of the
object may be fetched from $event->get_class.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'obj_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $timestamp = $event->get_timestamp

Returns the time at which the event was triggered.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_timestamp { local_date($_[0]->_get('timestamp'), $_[1]) }

################################################################################

=item my $key_name = $event->get_key_name

Returns the event key name. Same as the key name specified for the event type
defining this event.

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

=item my $name = $event->get_name

Returns the event name. Same as the name specified for the event type defining
this event.

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

=item my $description = $event->get_description

Returns the event description. Same as the name specified for the event type
defining this event.

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

=item my $class = $event->get_class

Returns name of the class of object for which the event was logged.

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

=item my $attr_href = $event->get_attr

Returns an anonymous hash of the attributes of the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'attr' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> Uses Bric::Util::Attribute::Event internally.

B<Notes:> NONE.

=item $self = $event->has_alerts

Returns true if alerts are associated with the event, and false if no alerts
are associated with the event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_alerts { $_[0]->_get('_alert') ? $_[0] : undef }

################################################################################

=item $self = $event->save;

Dummy method for those who try to call save() without realizing that saving is
automatic. Returns $self, but otherwise does noththing.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save { $_[0] }

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $events_aref = &$get_em( $pkg, $search_href )

=item my $events_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Person objects
or, if called with an optional third argument, returns a listof Bric::Biz::Person
object IDs (used by list_ids()).

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
	if ($k eq 'timestamp') {
	    # It's a date column.
	    if (ref $v) {
		# It's an arrayref of dates.
		push @wheres, "e.$k BETWEEN ? AND ?";
		push @params, (db_date($v->[0]), db_date($v->[1]));
	    } else {
		# It's a single value.
		push @wheres, "e.$k = ?";
		push @params, db_date($v);
	    }
       	} elsif ($num_map{$k}) {
	    # It's a numeric column.
	    push @wheres, $num_map{$k};
	    push @params, $v;
	} elsif ($txt_map{$k}) {
	    # It's a text-based column.
	    push @wheres, $txt_map{$k};
	    push @params, lc $v;
	}
    }

    local $" = ' AND ';
    my $where = @wheres ? " AND @wheres" : '';

    my $qry_cols = $ids ? ['e.id'] : \@cols;
    $" = ', ';
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   event e LEFT JOIN
                   (event_attr ea JOIN
                       event_type_attr ta ON ea.event_type_attr__id = ta.id)
                   ON e.id = ea.event__id,
               class c, event_type t
        WHERE  e.event_type__id = t.id
               AND t.class__id = c.id
              $where
        ORDER BY e.timestamp, e.id
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my ($last, @d, @init, $attr, $val, @events) = (-1);
    bind_columns($sel, \@d[0..$#props - 1], \$attr, \$val);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	if ($d[0] != $last) {
	    # Create a new object.
	    push @events, &$make_obj($pkg, \@init) unless $last == -1;
	    # Get the new record.
	    $last = $d[0];
	    @init = (@d, {});
	}
	# Grab any attributes.
	$init[$#init]->{$attr} = $val if $attr;
    }
    # Grab the last object.
    push @events, &$make_obj($pkg, \@init) if @init;
    # Return the objects.
    return \@events;
};

################################################################################

=item &$save($self)

Saves the contents of an event.

B<Throws:>

=over 4

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

$save = sub {
    my $self = shift;
    local $" = ', ';
    my $fields = join ', ', next_key('event'), ('?') x $#ecols;
    my $ins = prepare_c(qq{
        INSERT INTO event (@ecols)
        VALUES ($fields)
    }, undef, DEBUG);
    # Don't try to set ID - it will fail!
    execute($ins, $self->_get(@eprops[1..$#eprops]));
    # Now grab the ID.
    my $id = last_key('event');
    $self->_set({ id => $id });
    return $id;
};

################################################################################

=item &$save_attr($event_id, $et, $attr)

Saves the attributes of an event.

B<Throws:>

=over 4

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

$save_attr = sub {
    my ($eid, $et, $attr) = @_;
    my $ins = prepare_c(qq{
        INSERT INTO event_attr (event__id, event_type_attr__id, value)
        VALUES (?, ?, ?)
    }, undef, DEBUG);

    my $ret;
    my $et_attr = $et->get_attr;
    while (my ($aid, $name) = each %$et_attr) {
	execute($ins, $eid, $aid, $attr->{$name} || $attr->{lc $name});
	$ret->{$name} = $attr->{$name};
    }
    return $ret;
};

################################################################################]

=item my $event = &$make_obj( $pkg, $init )

Instantiates a Bric::Util::Event object. Used by &$get_em().

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

################################################################################

=item &$get_et($self)

Returns the Bric::Util::EventType object identifying the type of this
Bric::Util::Event object.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::EventType->lookup() internally and caches the object.

=cut

$get_et = sub {
    my $self = shift;
    my $et = $self->_get('_et');
    return $et if $et;
    $et = Bric::Util::EventType->lookup({ id => $self->_get('event_type_id') });
    $self->_set(['_et'], [$et]);
    return $et;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Util::EventType(3)
Bric::Util::AlertType(5)
Bric::Util::Alert(6)

=cut

