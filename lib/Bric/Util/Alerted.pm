package Bric::Util::Alerted;

=head1 NAME

Bric::Util::Alerted - Interface to Alerts as they are sent to individual users.

=head1 VERSION

$Revision: 1.8 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:36 $

=head1 SYNOPSIS

  use Bric::Util::Alerted;

  # Constructors.
  my $alerted = Bric::Util::Alerted->lookup({ id => 1 });
  my @alerteds = Bric::Util::Alerted->list($params);

  # Class Methods.
  my @alerted_ids = Bric::Util::Alerted->list_ids($params);
  my $bool = Bric::Util::Alerted->ack_by_id(@alerted_ids);

  # Instance Methods.
  my $id = $alerted->get_id;
  my $at_id = $alerted->get_alert_id;
  my $alert = $alerted->get_alert;
  my $uid = $alerted->get_user_id;
  my $user = $alerted->get_user;
  my @sent = $alerted->get_sent;

  $alerted = $alered->acknowledge;
  my $ack_time = $alerted->get_ack_time($format);

=head1 DESCRIPTION

This class is the interface to individual user Alerts. While Bric::Util::Alert
objects are created once for a given event, many different users may receive
those alerts. Bric::Util::Alerted provides access to those user-specific instances
of a particular alert. All methods by which a user is alerted are covered by a
single Bric::Util::Alerted object for that Bric::Util::Alert alert, and when a user
acknowledges an alert, all methods by which it was sent are acknowledged.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Fault::Exception::DP;
use Bric::Biz::Person::User;
use Bric::Util::Alert;
use Bric::Util::Alerted::Parts::Sent;
use Bric::Util::Time qw(:all);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $new);

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
my @cols = qw(a.id a.alert__id a.usr__id a.ack_time b.subject b.message
              b.timestamp);
my @by_cols = qw(c.type v.contact_value__value v.sent_time);
my @by_props = qw(type value sent_time);
my @props = qw(id alert_id user_id ack_time subject message timestamp);
my %map = (alert_id => 'a.alert__id = ?',
	   user_id => 'a.usr__id = ?');
my $meths;
my @ord = qw(alert_id alert user_id user ack_time subject message timestamp
	     sent);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id =>  Bric::FIELD_READ,
			 alert_id => Bric::FIELD_READ,
			 user_id => Bric::FIELD_READ,
			 ack_time => Bric::FIELD_READ,
			 subject => Bric::FIELD_READ,
			 message => Bric::FIELD_READ,
			 timestamp => Bric::FIELD_READ,

			 # Private Fields
			 _meths_sent=> Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $c = Bric::Util::Alerted->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::Alerted object based on the
Bric::Util::Alerted object ID passed. If $id is not found in the database,
lookup() returns undef.

B<Throws:>

=over

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

B<Side Effects:> If $id is found, populates the new Bric::Util::Alerted object
with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $alerted = &$get_em(@_);
    # We want @$alerted to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Util::Alerted objects found.' }) if @$alerted > 1;
    return @$alerted ? $alerted->[0] : undef;
}

################################################################################

=item my (@alerteds || $alerteds_aref) = Bric::Util::Alerted->list($params)

Returns a list or anonymous array of Bric::Util::Alerted objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

alert_id

=item *

user_id

=item *

ack_time - May pass in as an anonymous array of two values, the first the
minimum acknowledged time, the second the maximum acknowledged time. If the
first array item is undefined, then the second will be considered the date that
ack_time must be less than. If the second array item is undefined, then the
first will be considered the date that ack_time must be greater than. If the
value passed in is undefined, then the query will specify 'IS NULL'.

=back

The last two lookup keys, time_start and time_end, must be used together, as
they represent a range of dates between which to retrieve Bric::Util::Alerted
objects.

Any combination of these keys may be used, although the most common may be
alert_id or user_id.

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

B<Side Effects:> Populates each Bric::Util::Alerted object with data from the
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

=item my (@alrtd_ids || $alrtd_ids_aref) = Bric::Util::Alerted->list_ids($params)

Returns a list or anonymous array of Bric::Util::Alerted object IDs based on the
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

=back

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item $meths = Bric::Util::Alerted->my_meths

=item (@meths || $meths_aref) = Bric::Util::Alerted->my_meths(TRUE)

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
#my @ord = qw(alert_id alert user_id user ack_time subject message);

    # We don't got 'em. So get 'em!
    $meths = {
	      alert_id   => {
			     name     => 'alert_id',
			     get_meth => sub { shift->get_alert_id(@_) },
			     get_args => [],
			     disp     => 'Alert ID',
			     len      => 10,
			     req      => 1,
			     type     => 'short',
			    },
	      alert      => {
			     name     => 'alert',
			     get_meth => sub { shift->get_alert(@_) },
			     get_args => [],
			     disp     => 'Alert',
			     len      => 10,
			     req      => 1,
			     type     => 'short',
			    },
	      user_id   => {
			     name     => 'user_id',
			     get_meth => sub { shift->get_user_id(@_) },
			     get_args => [],
			     disp     => 'User ID',
			     len      => 10,
			     req      => 1,
			     type     => 'short',
			    },
	      user   => {
			     name     => 'user',
			     get_meth => sub { shift->get_user(@_) },
			     get_args => [],
			     disp     => 'User',
			     len      => 10,
			     req      => 1,
			     type     => 'short',
			    },
	      subject      => {
			     name     => 'subject',
			     get_meth => sub { shift->get_subject(@_) },
			     get_args => [],
			     disp     => 'Subject',
			     search   => 0,
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
			     disp     => 'Time Sent',
			     search   => 1,
			     len      => 512,
			     req      => 0,
			     type     => 'short',
			    },
	      ack_time  => {
			     name     => 'ack_time',
			     get_meth => sub { shift->get_ack_time(@_) },
			     get_args => [],
			     disp     => 'Acknowledged',
			     search   => 0,
			     len      => 512,
			     req      => 0,
			     type     => 'short',
			    },
	      sent       => {
			     name     => 'sent',
			     get_meth => sub { shift->get_sent(@_) },
			     get_args => [],
			     disp     => 'Methods Sent',
			     search   => 0,
			     len      => 512,
			     req      => 0,
			     type     => 'short',
			    },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my $bool = Bric::Util::Alerted->ack_by_id(@alerted_ids)

If a whole bunch of alerteds need to be acknowledged at once, use this method
and simply pass in all of their IDs, rather than instantiating each one and
acknowledging it in turn. This will dramatically cut down on the overhead, as
ack_by_id() will execute fewer queries.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub ack_by_id {
    my $self = shift;
    my $date = db_date(undef, 1);
    $self->_set(['ack_time'], [$date]) if ref $self;

    my $upd = prepare_c(qq{
        UPDATE alerted
        SET    ack_time = ?
        WHERE  id = ?
    });

    # Acknowledge each Bric::Util::Alerted object by its ID.
    execute($upd, $date, $_) for @_;
    return ref $self ? $self : 1;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $alerted->get_id

Returns the ID of the Bric::Util::Alerted object.

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

B<Notes:> If the Bric::Util::Alerted object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $user = $alerted->get_user

Returns the Bric::Biz::Person::User object representing the user to whom the
alert was sent.

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

B<Side Effects:> Uses Bric::Biz::Person::User->lookup() internally.

B<Notes:> NONE.

=cut

sub get_user {
    my $self = shift;
    Bric::Biz::Person::User->lookup({ id => $self->_get('user_id')});
}

=item my $uid = $alerted->get_user_id

Returns the Bric::Biz::Person::User object ID representing the user to whom the
alert was sent.

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

=item my $alert = $alerted->get_alert

Returns the Bric::Util::Alert object representing the alert for which this
Bric::Util::Alerted object was created.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_alert {
    my $self = shift;
    Bric::Util::Alert->lookup({ id => $self->_get('alert_id')});
}

=item my $aid = $alerted->get_alert_id

Returns the id of the Bric::Util::Alert object representing the alert for which
this Bric::Util::Alerted object was created.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'alert_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $subject = $alerted->get_subject

=item my $subject = $alerted->get_name

Returns the subject of the alert for which this recipient was notified.

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

=item my $msg = $alerted->get_message

Returns the message of the alert for which this recipient was notified.

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

=item my $timestamp = $alerted->get_timestamp($format)

Returns the time at which the alert was sent to the user. Pass in a strftime
formatting string to get the time formatted by that format; otherwise, the time
will be formatted in the format splecified for the 'Date/Time Format'
preference.

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

=item my $ack_time = $alerted->get_ack_time($format)

Returns the time at which the alert has been acknowledged by the user to whom it
was sent. Pass in a strftime formatting string to get the time formatted by that
format; otherwise, the time will be formatted in the format splecified for the
'Date/Time Format' preference. Returns undef if the alert has not yet been
acknowledged. Call acknowledge() to acknowledge the alert.

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

sub get_ack_time { local_date($_[0]->_get('ack_time'), $_[1]) }

=item $self = $alerted->acknowledge

Acknowledges the alert. Call this method when the user who was sent the alert
acknowledges receipt of the alert. The ack_time property will then be filled
enumerated. This is the only method that updates the Bric::Util::Alerted object,
and can only be called once. If the Bric::Util::Alerted object has already been
acknowledged, this method will return undef; otherwise it will return $self.

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

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub acknowledge {
    my $self = shift;
    my ($id, $ack) = $self->_get('id', 'ack_time');
    return if $ack;       # We only want to acknowledge an alert once.
    ack_by_id($self, $id);
}

=item my (@sent || $sent_aref) = $alerted->get_sent

Returns a list or anonymous array of Bric::Util::Alerted::Parts::Sent objects.
These objects describe how the user was alerted and at what time. See
Bric::Util::Alerted::Parts::Sent for its interface.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_sent {
    my $self = shift;
    return wantarray ? @{ $self->_get('_meths_sent') }
      : $self->_get('_meths_sent');
}

=item $self = $p->save

No-op.

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
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'ack_time') {
	    # It's a date column.
	    if (ref $v) {
		# It's an arrayref of dates.
		if (!defined $v->[0]) {
		    # It's less than.
		    push @wheres, "a.$k < ?";
		    push @params, db_date($v->[1]);
		} elsif (!defined $v->[1]) {
		    # It's greater than.
		    push @wheres, "a.$k > ?";
		    push @params, db_date($v->[0]);
		} else {
		    # It's between two sizes.
		    push @wheres, "a.$k BETWEEN ? AND ?";
		    push @params, (db_date($v->[0]), db_date($v->[1]));
		}
	    } elsif (!defined $v) {
		# It needs to be null.
		push @wheres, "a.$k IS NULL";
	    } else {
		# It's a single value.
		push @wheres, "a.$k = ?";
		push @params, db_date($v);
	    }
       	} else {
	    push @wheres, $map{$k} || "a.$k = ?";
	    push @params, $v;
	}
    }

    local $" = ' AND ';
    my $where = @wheres ? "AND @wheres" : '';

    $" = ', ';
    my @qry_cols = $ids ? ('DISTINCT a.id') : (@cols, @by_cols);
#my @by_cols = qw(c.type v.contact_value__value v.sent_time);
#my @by_props = qw(type value sent_time); 
   my $sel = prepare_c(qq{
        SELECT @qry_cols
        FROM   alerted a, alerted__contact_value v, contact c,
               alert b
        WHERE  a.id = v.alerted__id
               AND b.id = a.alert__id
               AND v.contact__id = c.id
               $where
        ORDER BY a.id
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @a, @alerteds, %obj, @bys);
    bind_columns($sel, \@d[0..$#cols], \@a[0..$#by_cols]);

    while (fetch($sel)) {
	@obj{@props} = @d unless $obj{id};
	if ( $d[0] != $obj{id} ) {
	    # It's a new object. Save the last one.
	    push @alerteds, &$new($pkg, \%obj);
	    # Now grab the new object.
	    %obj = ();
	    @obj{@props} = @d;
	}

	# Grab any parts. These will vary from row to row.
	if ($a[0]) {
	    my %by;
	    @by{@by_props} = @a;
	    push @{ $obj{_meths_sent} },
	      Bric::Util::Alerted::Parts::Sent->new(\%by);
	}
    }
    # Grab the last one!
    push @alerteds, &$new($pkg, \%obj) if %obj;
    finish($sel);
    return \@alerteds;
};

=item my $addr = &$new($pkg, $init)

Instantiates a new object. Used in place of new() by &$get_em(), since new isn't
implemented for this class.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$new = sub {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
    $self->_set__dirty; # Disables dirty flag.
    return $self;
};

1;
__END__

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

