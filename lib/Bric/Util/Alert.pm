package Bric::Util::Alert;

=head1 NAME

Bric::Util::Alert - Interface to Bricolage Alerts

=head1 VERSION

$Revision: 1.13 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2003-02-18 02:30:26 $

=head1 SYNOPSIS

  use Bric::Util::Alert;

  # Constructors.
  my $alert = Bric::Util::Alert->new($init);
  $alert = Bric::Util::Alert->lookup({ id => 1 });
  my @alerts = Bric::Util::Alert->list($params);

  # Class Methods.
  my @alert_ids = Bric::Util::Alert->list_ids($params);

  # Instance Methods.
  my $id = $alert->get_id;
  my $at = $alert->get_alert_type;
  my $at_id = $alert->get_alert_type_id;
  my $event = $alert->get_event;
  my $event_id = $alert->get_event_id;
  my $subject = $alert->get_subject;
  my $message = $alert->get_message;
  my $timestamp = $alert->get_timestamp($format);
  my @alerted = $alert->get_alerted;

=head1 DESCRIPTION

This class offers an interface to alerts created when an event evaluates truly
the rules defined for a Bric::Util::AlertType object. It provides basic accessors
to the properties of an individual alert, including a list of Bric::Util::Alerted
objects representing the users who were sent the alert, when they were sent it,
and when they acknolwedged the alert. See Bric::Util::Alerted for more
information.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:alert);
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::AlertType;
use Bric::Util::Alerted;
use Bric::Util::EventType;
use Bric::Util::Event;
use Bric::Util::Time qw(:all);
use Bric::Util::Trans::Mail;
#use Bric::Util::Trans::Jabber;
use Bric::Util::Fault::Exception::DP;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $replace, $send_em);

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
# Identifies databse columns and object keys.
my @cols = qw(id event__id alert_type__id subject message timestamp);
my @props = qw(id event_id alert_type_id subject message timestamp);
my %map = (id => 'id',
           timestamp => 'timestamp',
           event_id => 'event__id',
           alert_type_id => 'alert_type__id'
);

# How we know what libraries to use for sending alerts.
my %send = map { $_ => 'Bric::Util::Trans::Mail' }
  ('Primary Email', 'Secondary Email', 'Pager Email');
# IM is not yet supported.
#$send{$_} = 'Bric::Util::Net::Jabber' for
#  ('AIM ID', 'ICQ ID', 'MSN ID', 'Yahoo! Pager ID', 'Jabber ID');

my $meths;
my @ord = qw(event_id event alert_type_id alert_type subject message timestamp);

################################################################################
################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         event_id => Bric::FIELD_READ,
                         alert_type_id => Bric::FIELD_READ,
                         subject => Bric::FIELD_READ,
                         message => Bric::FIELD_READ,
                         timestamp => Bric::FIELD_READ

                         # Private Fields
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $c = Bric::Util::Alert->new

=item my $c = Bric::Util::Alert->new($init)

Instantiates a Bric::Util::Alert object. An anonymous hash of initial values may
be passed. The required initialization keys are:

=over 4

=item *

at - A Bric::Util::AlertType object defining the type of alert this is.

=item *

event - A Bric::Util::Event object representing the event for which this alert is
created.

=item *

obj - The Bricolage object for which the event was triggered. Its properties and
attributes will be used to replace variables in the alert subject and message.

=item *

user - The Bric::Biz::Person::User object representing the user who triggered the
event and hence this alert. Its properties and attributes will be used to
replace variables in the alert subject and message.

=back

The alert will be saved to the database upon creation and cannot be changed in
any way after it has been created. Only Bric::Util::Alerted objects, which
represent the users to whom the alert was sent, may have their acknowledged
properties set. See Bric::Util::Alerted for its interface.

Generally this method will not be called directly, but by the
Bric::Util::AlertType->send_alerts() method, which will be called by
Bric::Util::Event->new(). Use lookup() and list() to retrieve pre-existing alerts.

B<Throws:>

=over

=item *

Bric::Util::Alert::new() requires a Bricolage object, a Bric::Biz::Person::User object, a
Bric::Util::AlertType object, and a Bric::Util::Event object.

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

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field required.

=item *

Access denied: WRITE access for field required.

=item *

No AUTOLOAD method.

=item *

Unable to send mail.

=item *

Unable to send instant message.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $args) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    my ($at, $event, $user, $obj) = @{$args}{qw(at event user obj)};
    my $init = {};

    # Make sure we have all the parts we need.
    die Bric::Util::Fault::Exception::DP->new({
      msg => __PACKAGE__ . '::new() requires a Bricolage object, a Bric::Biz::Person::User'
             . ' object, a Bric::Util::AlertType object, and a Bric::Util::Event'
             . ' object' }) unless $event && $at && $obj && $user;

    # Get the attributes of this event, if any. Make sure they're lowercase and
    # have variable-specific keys.
    my $attr = $event->get_attr || {};
    $attr = { map {
        (my $v = lc $_) =~ s/\W+/_/g;
        lc $v => $attr->{$_}
    } keys %$attr };

    # Grab the message, substituting simple variables for their values. This is
    # where we fill the message in with event-specific information. We simply
    # search for instances of $ followed by a word (but not preceded by a
    # backslash), and replace it with the proper value. See &$replace() below to
    # see how it's done.
    ($init->{message} = $at->get_message) =~
      s/(?<!\\)\$(\w+)/&$replace($1, $attr, $obj, $user)/ge;
    ($init->{subject} = $at->get_subject) =~
      s/(?<!\\)\$(\w+)/&$replace($1, $attr, $obj, $user)/ge;

    # Make sure any legal instances of "\$" are chanaged to '$' and make sure
    # the fields aren't too long.
    $init->{message} =~ s/\\\$/\$/g;
    $init->{subject} =~ s/\\\$/\$/g;
    $init->{message} = substr $init->{message}, 0, 512
      if length $init->{message} > 512;
    $init->{subject} = substr $init->{subject}, 0, 128
      if length $init->{subject} > 128;

    $init->{alert_type_id} = $at->get_id;   # Grab the alert type.
    $init->{event_id} = $event->get_id;     # Grab the event ID.
    $init->{timestamp} = db_date(undef, 1); # Grab the current time.

    # Save it to the database.
    my $fields = join ', ', next_key('alert'), ('?') x $#cols;
    local $" = ', ';
    my $sth = prepare_c(qq{
        INSERT INTO alert (@cols)
        VALUES ($fields)
        }, undef, DEBUG);
    execute($sth, @{$init}{@props[1..$#props]});
    # Grab its new ID.
    $init->{id} = last_key('alert');

    # Now send all the individual alerts.
    &$send_em($init, $at, $event);
    $self->SUPER::new($init);
}

################################################################################

=item my $c = Bric::Util::Alert->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::Alert object based on the
Bric::Util::Alert object ID passed. If $id is not found in the database, lookup()
returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::Alert objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Util::Alert object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $alert = $pkg->cache_lookup(@_);
    return $alert if $alert;

    $alert = $get_em->($pkg, @_);
    # We want @$alert to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Util::Alert objects found.' }) if @$alert > 1;
    return @$alert ? $alert->[0] : undef;
}

################################################################################

=item my (@alerts || $alerts_aref) = Bric::Util::Alert->list($params)

Returns a list or anonymous array of Bric::Util::Alert objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

alert_type_id

=item *

event_id

=item *

subject

=item *

message

=item *

timestamp

=item *

no_ack

=item *

time_start and time_end

=back

The last two lookup keys, time_start and time_end, must be used together, as
they represent a range of dates between which to retrieve Bric::Util::Alert
objects. Set no_ack to true to have list() return only unacknowledged alerts.

Any combination of these keys may be used, although the most common may be
event_id or a combination of alert_type_id and no_ack.

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

B<Side Effects:> Populates each Bric::Util::Alert object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

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

=item my (@alert_ids || $alert_ids_aref) = Bric::Util::Alert->list_ids($params)

Returns a list or anonymous array of Bric::Util::Alert object IDs based on the
search parameters passed via an anonymous hash. The supported lookup keys are
the same as those for list().

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

=item $meths = Bric::Util::Alert->my_meths

=item (@meths || $meths_aref) = Bric::Util::Alert->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Alert->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              event_id   => {
                             name     => 'event_id',
                             get_meth => sub { shift->get_event_id(@_) },
                             get_args => [],
                             disp     => 'Event ID',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                            },
              event      => {
                             name     => 'event',
                             get_meth => sub { shift->get_event(@_) },
                             get_args => [],
                             disp     => 'Event',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                            },
              alert_type_id   => {
                             name     => 'alert_type_id',
                             get_meth => sub { shift->get_alert_type_id(@_) },
                             get_args => [],
                             disp     => 'Alert Type ID',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                            },
              alert_type   => {
                             name     => 'alert_type',
                             get_meth => sub { shift->get_alert_type(@_) },
                             get_args => [],
                             disp     => 'Alert Type',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                            },
              subject      => {
                             name     => 'subject',
                             get_meth => sub { shift->get_subject(@_) },
                             get_args => [],
                             disp     => 'Subject',
                             len      => 128,
                             req      => 0,
                             type     => 'short',
                            },
              message      => {
                             name     => 'message',
                             get_meth => sub { shift->get_message(@_) },
                             get_args => [],
                             disp     => 'Message',
                             search   => 0,
                             len      => 512,
                             req      => 0,
                             type     => 'short',
                            },
              timestamp  => {
                             name     => 'timestamp',
                             get_meth => sub { shift->get_timestamp(@_) },
                             get_args => [],
                             disp     => 'Time',
                             search   => 1,
                             len      => 512,
                             req      => 0,
                             type     => 'short',
                            },
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $alert->get_id

Returns the ID of the Bric::Util::Alert object.

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

B<Notes:> If the Bric::Util::Alert object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $at = $alert->get_alert_type

Returns the Bric::Util::AlertType object defining this Alert.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::AlertType objects found.

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

sub get_alert_type {
    my $self = shift;
    Bric::Util::AlertType->lookup({ id => $self->_get('alert_type_id')});
}

=item my $at_id = $alert->get_alert_type_id

Returns the ID of the Bric::Util::AlertType object defining this Alert.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'alert_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $event = $alert->get_event

Returns the Bric::Util::Event object for which this alert was sent.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_event {
    my $self = shift;
    Bric::Util::Event->lookup({ id => $self->_get('event_id')});
}

=item my $eid = $alert->get_event_id

Returns the id of the Bric::Util::Event object for which this alert was sent.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'event_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $subect = $alert->get_subject

=item my $subject = $alert->get_name

Returns the text inserted into the subject line of this alert (where it's
appropriate to do so, e.g., email). This subject is different from that defined
by the Bric::Util::AlertType object on which this event is based in that any
variables included in the Bric::Util::AlertType object's subject will be
interpolated with their event-specific values. See
Bric::Util::AlertType::set_subject() for more information.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'message' required.

=item *

No AUTOLOAD method.

=item *

Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_name { $_[0]->_get('subject') }

=item my $message = $alert->get_message

Returns the message sent in this alert. This message is different from the one
defined by the Bric::Util::AlertType object on which this event is based in that
any variables included in the Bric::Util::AlertType object's message will be
interpolated with their event-specific values. See
Bric::Util::AlertType::set_message() for more information.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'message' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $timestamp = $alert->get_timestamp($format)

Returns the time the alert was created. This differs from the times the alert
was actually sent to various users by various means. That time can be retreived
from individual Bric::Util::Alerted objects. get_timestmp() will take as an
argument a strftime format string and return the time in that format. If not
provided, the format returned will default to the ISO 8601 timedate format, in
the users local time zone.

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

=item my (@alerted || $alerted_aref) = $alert->get_alerted

  foreach my $alerted ($alert->get_alerted) {
      print "Name:    ", $alerted->get_name, "\n";
      print "Message: ", $alerted->get_message, "\n";
      $alerted->acknowledge;
  }

Returns a list of Bric::Util::Alerted objects representing the users who were sent
this alert, how they were sent the alert, and when. The Bric::Util::Alerted object
is also used to acknowledge individual users' alerts. See Bric::Util::Alerted for
its interface.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::Alerted objects found.

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

sub get_alerted {
    my $self = shift;
    Bric::Util::Alerted->list({ alert_id => $self->_get('id')});
}

################################################################################

=item $self = $p->save

No-op.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save { $_[0] }

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $alerts_aref = &$get_em( $pkg, $params )

=item my $alert_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::Alert objects
or, if called with an optional third argument, returns a list of Bric::Util::Alert
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
    my (@txt_wheres, @num_wheres, @params);
    while (my ($k, $v) = each %$params) {
        next if $k eq 'time_end';
        if ($k eq 'time_start') {
            push @num_wheres, 'timetamp BETWEEN ? AND ?';
            push @params, @{$params}{qw(time_start time_end)};
        } elsif ($k eq 'subject' || $k eq 'message') {
            push @txt_wheres, "LOWER($k)";
            push @params, lc $v;
        } else {
            push @num_wheres, $map{$k};
            push @params, $v;
        }
    }

    # Assemble the WHERE clause.
    my $where = '';
    local $" = ' = ? AND ';
    $where = "WHERE  @num_wheres = ?" if @num_wheres;
    local $" = ' LIKE ? AND ';
    $where .= $where ? "AND @txt_wheres LIKE ?" : "WHERE  @txt_wheres LIKE ?"
      if @txt_wheres;

    # Assemble and prepare the query.
    local $" = ', ';
    my @qry_cols = $ids ? ('id') : @cols;
    my $sel = prepare_c(qq{
        SELECT @qry_cols
        FROM   alert
        $where
        ORDER BY timestamp
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @alerts);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        # Create a new object for each row.
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disable the dirty flag.
        push @alerts, $self->cache_me;
    }
    finish($sel);
    # Return the objects.
    return \@alerts;
};

=item my $string = &$replace($string, $attr, $obj, $user)

This function is used by the regular expression in new() to add elements to
messages based on simple variables in the Bric::Util::AlertType subject and
message fields.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$replace = sub {
    my ($key, $attr, $obj, $user) = @_;
    # This hash tells us how to get trigger user data.
    if (my $tmeths = Bric::Util::EventType->my_trig_meths->{$key}) {
        # Grab it from the Bric::Biz::Person::User object.
        my ($meth, $args) = @{$tmeths}{'get_meth', 'get_args'};
        return &$meth($user, @$args) || '';
    }

    # If not a trigger property, then grab it from the attributes.
    return $attr->{$key} if exists $attr->{$key};

    # Return null string unless it's an object property.
    my $omeths = $obj->my_meths->{$key} || return '';

    # Ah, it's an object property. So grab it from the object.
    my ($meth, $args) = @{$omeths}{'get_meth', 'get_args'};
    return &$meth($obj, @$args) || '';
};

=item my $bool = &$send_em($self, $at, $event)

Sends individual alerts to their recipients, and creates new Bric::Util::Alerted
objects for each one of them.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$send_em = sub {
    # This function could in theory create individual Bric:Util::Alerted
    # objects, calling new() for each one, and let each one log stuff to the
    # database, but that seems like a waste of overhead, since this function
    # is only called internally, and therefore doesn't need access to
    # individual Bric::Util::Alerted objects. So I just do it all here.
    my ($self, $at, $event) = @_;

    # Use this sth to insert users into alerted.
    my $ins_alerted = prepare_c(qq{
        INSERT INTO alerted (id, usr__id, alert__id)
        VALUES (${\next_key('alerted')}, ?, ?)
    }, undef, DEBUG);

    # Use this sth to insert each contact by which a user was alerted.
    my $insert_by = prepare_c(qq{
        INSERT INTO alerted__contact_value
               (alerted__id, contact__id, contact_value__value, sent_time)
        VALUES (?, ?, ?, ?)
    }, undef, DEBUG);

    my %alerted;
    my %ctypes = Bric::Biz::Contact->href_alertable_type_ids;
    while (my ($ctype, $cid) = each %ctypes) {
        # Get a list of unique User IDs in the groups.
        my (%users, %email);
        foreach my $uid ($at->get_user_ids($ctype),
                 map { Bric::Util::Grp::User->get_member_ids($_) }
                         $at->get_grp_ids($ctype) ) {
            foreach my $c
              (Bric::Biz::Person::User->lookup({ id => $uid })->get_contacts) {
                  next unless $c->get_type eq $ctype;
                  my $e = $c->get_value;
                  $users{$uid}->{$e} = 1;
                  $email{$e} = 1
              }
        }

        # Now send the email.
        my $m = Bric::Util::Trans::Mail->new({ from => ALERT_FROM,
                                             &ALERT_TO_METH => [ keys %email ],
                                             subject => $self->{subject},
                                             message => $self->{message}
                                           });
        eval { $m->send; };
        my $time = $@ ? (warn "Alert Emailing failed: $@\n", undef)[1]
          : db_date(undef, 1);

        while (my ($uid, $uemails) = each %users) {
            # Insert the user into alerted unless we already did.
            unless ($alerted{$uid}) {
                execute($ins_alerted, $uid, $self->{id});
                $alerted{$uid} = last_key('alerted');
            }

            # Now log the alert by this method. Don't include the time if the
            # message wasn't sent to a user.
            foreach my $e (keys %$uemails) {
                execute($insert_by, $alerted{$uid}, $cid, $e, $time);
            }
        }
    }
    return 1;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Util::AlertType|Bric::Util::AlertType>,
L<Bric::Util::EventType|Bric::Util::EventType>,
L<Bric::Util::Event|Bric::Util::Event>

=cut

