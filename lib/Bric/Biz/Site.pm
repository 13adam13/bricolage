package Bric::Biz::Site;

=head1 NAME

Bric::Biz::Site - Interface to Bricolage Site Objects

=head1 VITALS

=over 4

=item Version

$Revision: 1.1.2.9 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1.2.9 $ )[-1];

=item Date

$Date: 2003-03-09 01:06:19 $

=item CVS ID

$Id: Site.pm,v 1.1.2.9 2003-03-09 01:06:19 wheeler Exp $

=back

=head1 SYNOPSIS

  use Bric::Biz::Site;

  # Constructors.
  my $site = Bric::Biz::Site->new($init);
  $site = Bric::Biz::Site->lookup({ id => $id });
  my @sites = Bric::Biz::Site->list($params);

  # Class Methods.
  my @site_ids = Bric::Biz::Site->list_ids($params);
  my $meths = Bric::Biz::Site->my_meths;

  # Instance methods.
  $id = $site->get_id;
  my $name = $site->get_name;
  $site = $site->set_name($name)
  my $desc = $site->get_description;
  $site = $site->set_description($desc);
  my $domain_name = $site->get_domain_name;
  $site = $site->set_domain_name($domain_name);

  $site = $site->activate;
  $site = $site->deactivate;
  $site = $site->is_active;

  # Save the changes to the database
  $site = $site->save;

=head1 DESCRIPTION

Site are first-class Bricolage objects designed to manage different sites from
within a single Bricolage instance.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::Grp::Site;
use Bric::Util::Grp::User;
use Bric::Util::Grp::Asset;
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Fault qw(throw_da throw_not_unique);
use Bric::Util::Priv;
use Bric::Config qw(:qa);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric);

##############################################################################
# Function and Closure Prototypes
##############################################################################
my ($get_em, $set_unique_attr, $rename_grps);

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Site';
use constant INSTANCE_GROUP_ID => 47;

##############################################################################
# Fields
##############################################################################
# Private Class Fields

my $TABLE = 'site';
my @COLS =  qw(id name description domain_name active);
my @PROPS = qw(id name description domain_name _active);

my $SEL_COLS = 'a.' . join(', a.', @COLS) . ', m.grp__id';
my @SEL_PROPS = (@PROPS, 'grp_ids');

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields
      ({
        # Public Fields
        id          => Bric::FIELD_READ,
        name        => Bric::FIELD_RDWR,
        description => Bric::FIELD_RDWR,
        domain_name => Bric::FIELD_RDWR,
        grp_ids     => Bric::FIELD_READ,

        # Private Fields
        _active     => Bric::FIELD_NONE,
        _asset_grp  => Bric::FIELD_NONE,
        _rename     => Bric::FIELD_NONE,
       });
}

##############################################################################
# Constructors.
##############################################################################

=head1 INTERFACE

=head2 Constructors

=head3 new

  my $site = Bric::Biz::Site->new;
  $site = Bric::Biz::Site->new($init);

Constructs a new site object and returns it. An anonymous hash of initial
values may be passed. The supported keys for that hash references are:

=over 4

=item name

=item description

=item domain_name

=back

The C<name> and C<domain_name> attributes must be globally unique or an
exception will be thrown.

B<Throws:>

=over

=item Exception::DA

=item Error::NotUnique

=back

=cut

sub new {
    my ($invocant, $init) = @_;
    $init->{_active} = 1;
    $init->{grp_ids} = [INSTANCE_GROUP_ID];
    my ($name, $domain_name) = delete @{$init}{qw(name domain_name)};
    my $self = $invocant->SUPER::new($init);
    $self->set_name($name) if $name;
    $self->set_domain_name($domain_name) if $domain_name;
    return $self;
}

################################################################################

=head3 lookup

  my $site = Bric::Biz::Site->lookup({ id => $id });
  $site = Bric::Biz::Site->lookup({ name => $name });
  $site = Bric::Biz::Site->lookup({ domain_name => $domain_name });

Looks up and constructs an existing site object in the database and returns
it. A Site ID, name, or domain name can be used as the site object unique
identifier to look up. If no site object is found in the database, then
C<lookup()> will return C<undef>.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub lookup {
    my $invocant = shift;
    # Look for the site in the cache, first.
    my $site = $invocant->cache_lookup(@_);
    return $site if $site;

    # Look up the site in the database.
    my $class = ref $invocant || $invocant;
    $site = $get_em->($class, @_) or return;

    # Throw an exception if we looked up more than one site.
    throw_da "Too many $class objects found" if @$site > 1;

    return $site->[0];
}

##############################################################################

=head3 list

  my @sites = Bric::Biz::Site->list($params);
  my $sites_aref = Bric::Biz::Site->list($params);

Returns a list or anonymous array of site objects based on the search
parameters passed via an anonymous hash. The supported lookup keys that may
use valid SQL wild card characters are:

=over

=item name

=item description

=item domain_name

=back

The supported lookup keys that must be an exact value are:

=over 4

=item active

A boolean value indicating if the site is active.

=item grp_id

A Bric::Util::Grp::Site object ID.

=back

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub list { $get_em->(@_) }

##############################################################################
# Class Methods
##############################################################################

=head2 Class Methods

=head3 list_ids

  my @site_ids = Bric::Biz::Site->list_ids($params);
  my $site_ids_aref = Bric::Biz::Site->list_ids($params);

Returns a list or anonymous array of site object IDs based on the search
parameters passed via an anonymous hash. The supported lookup keys are the
same as for the C<list()> method.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub list_ids { $get_em->(@_, 1) }

##############################################################################

=head3 my_meths

  my $meths = Bric::Biz::Site->my_meths
  my @meths = Bric::Biz::Site->my_meths(1);
  my $meths_aref = Bric::Biz::Site->my_meths(1);
  @meths = Bric::Biz::Site->my_meths(0, 1);
  $meths_aref = Bric::Biz::Person->my_meths(0, 1);

Returns Bric::Biz::Site attribute accessor introspection data. See
L<Bric|Bric> for complete documtation of the format of that data. Returns
accessor introspection data for the following attributes:

=over

=item name

The site name. A unique identifier attribute.

=item domain_name

The site domain name. A unique identifier attribute.

=item description

A description of the site.

=item active

The site's active status boolean.

=back

=cut

{
    my @ORD = qw(name domain_name description active);
    my $METHS =
      { name        => { name     => 'name',
                         get_meth => sub { shift->get_name(@_) },
                         get_args => [],
                         set_meth => sub { shift->set_name(@_) },
                         set_args => [],
                         disp     => 'Name',
                         search   => 1,
                         req      => 1,
                         props    => { type   => 'text',
                                       length => 32
                                     }
                       },
        domain_name => { name     => 'domain_name',
                         get_meth => sub { shift->get_domain_name(@_) },
                         get_args => [],
                         set_meth => sub { shift->set_domain_name(@_) },
                         set_args => [],
                         disp     => 'Domain Name',
                         req      => 1,
                         props    => { type   => 'text',
                                       length => 32
                                     }
                       },
        description => { name     => 'description',
                         get_meth => sub { shift->get_description(@_) },
                         get_args => [],
                         set_meth => sub { shift->set_description(@_) },
                         set_args => [],
                         disp     => 'Description',
                         props    => { type => 'textarea',
                                       cols => 40,
                                       rows => 4
                                     }
                       },
        active      => { name     => 'active',
                         get_meth => sub { shift->is_active(@_) ? 1 : 0 },
                         get_args => [],
                         set_meth => sub { $_[1] ? shift->activate(@_)
                                             : shift->deactivate(@_)
                                         },
                         set_args => [],
                         disp     => 'Active',
                         len      => 1,
                         req      => 1,
                         props    => { type => 'checkbox' }
                       },
      };

    sub my_meths {
        my ($invocant, $ord, $ident) = @_;
        if ($ord) {
            return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
        } elsif ($ident) {
            return wantarray ? @{$METHS}{qw(name domain_name)} :
              [@{$METHS}{qw(name domain_name)}];
        } else {
            return $METHS;
        }
    }
}

##############################################################################
# Instance Methods
##############################################################################

=head2 Accessors

=head3 id

  my $id = $site->get_id;

Returns the site object's unique database ID.

=head3 name

  my $name = $site->get_name;
  $site = $site->set_name($name);

Get and set the site object's unique name. The value of this attribute must be
case-insensitively globally unique. If a non-unique value is passed to
C<set_name()>, an exception will be thrown.

B<Throws:>

=over

=item Error::NotUnique

=back

=cut

sub set_name { $set_unique_attr->('name', @_) }

=head3 description

  my $description = $site->get_description;
  $site = $site->set_description($description);

Get and set the site object's description.

=head3 domain_name

  my $domain_name = $site->get_domain_name;
  $site = $site->set_domain_name($domain_name);

Get and set the site object's unique domain name. The value of this attribute
must be case-insensitively globally unique. If a non-unique value is passed to
C<set_domain_name()>, an exception will be thrown.

B<Throws:>

=over

=item Error::NotUnique

=back

=cut

sub set_domain_name { $set_unique_attr->('domain_name', @_) }

=head3 active

  $site = $site->activate;
  $site = $site->deactivate;
  $site = $site->is_active;

Get and set the site object's active status. C<activate()> and C<deactivate()>
each return the site object. C<is_active()> returns the site object when the
site is active, and C<undef> when it is not.

=cut

sub activate { $_[0]->_set(['_active'], [1]) }
sub deactivate { $_[0]->_set(['_active'], [0]) }
sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

##############################################################################

=head2 Instance Methods

=head3 save

  $site = $site->save;

Saves any changes to the site object to the database. Returns the site object
on success and throws an exception on failure.

B<Side Effects:> Creates five internal permanent groups. One is a
Bric::Util::Grp::Asset group. Its ID is used for the site ID, so that it can
easily be used by Bric::Biz::Asset to add the ID to its C<grp_ids> attribute
because every asset is related to a site. The other four are
Bric::Util::Grp::User groups, and one is created for each permission, READ,
EDIT, CREATE, and DENY. Furthermore, a Bric::Util::Priv object is created for
each of these user groups in turn, to grant their users the appropriate
permissions to any assets associated with the site.

B<Thows:>

=over 4

=item Exception::DA

=back

=cut

sub save {
    my $self = shift;
    return $self unless $self->_get__dirty;
    my $id = $self->_get('id');

    if ($id) {
        # Update the record in the database.
        my $set_cols = join ' = ?, ', @COLS;
        my $upd = prepare_c(qq{
            UPDATE $TABLE
            SET    $set_cols = ?
            WHERE  id = ?
        }, undef, DEBUG);

        # Make it so.
        execute($upd, $self->_get(@PROPS), $id);

        # Rename the groups, if need be.
        $rename_grps->($self) if $self->_get('_rename');
    } else {
        # Create a new permanent secret asset group for this site.
        my $grp = Bric::Util::Grp::Asset->new
          ({ name      => 'Secret Site Asset Group',
             permanent => 1,
             secret    => 1 });
        $grp->save;

        # Swipe the group's ID for our own!
        $id = $grp->get_id;
        $self->_set([qw(id _grp)], [$id, $grp]);

        # Insert a new record into the database.
        my $value_cols = join ', ', ('?') x @COLS;
        my $ins_cols = join ', ', @COLS;
        my $ins = prepare_c(qq{
            INSERT INTO $TABLE ($ins_cols)
            VALUES ($value_cols)
        }, undef, DEBUG);

        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@PROPS));

        # Register this site in the "All Sites" group and add the group ID.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
        $self->_set(['grp_ids'], [[INSTANCE_GROUP_ID]]);

        # Create user permission groups.
        my $name = $self->get_name;
        my $privs = Bric::Util::Priv->vals_href ;
        while (my ($priv, $field) = each %$privs) {
            my $g = Bric::Util::Grp::User->new
              ({ name        => "$name $field Users",
                 description => "__Site $id Users__",
                 secret      => 1,
                 permanent   => 1});
            $g->save;
            Bric::Util::Priv->new({ obj_grp => $grp,
                                    usr_grp => $g,
                                    value   => $priv })->save;
        }
    }

    # Finish up.
    $self->SUPER::save;
}

##############################################################################

=begin private

=head2 Private Instance Methods

These methods are included for the sake of completeness, but since there
appears to be no use for them currently, I'm keeping them private for now.

=head3 get_asset_grp

  my $site_grp = $site->get_asset_grp;

Returns the group object for this site. Used for creating permissions objects.

B<Note:> Do I<not> change the name, description, or permission associations of
the asset group. Those functions are handled internally by Bric::Biz::Site.
Just use this group to add and remove users you wish to associate with a site.

B<Thows:>

=over 4

=item Exception::DA

=back

=cut

sub get_asset_grp {
    my $self = shift;
    my ($id, $grp) = $self->_get(qw(id _asset_grp));
    return $grp if $grp;
    return unless $id;
    $grp = Bric::Util::Grp::Asset->lookup({ id => $id });
    $self->_set(['_asset_grp'], [$grp]);
    return $grp;
}

##############################################################################

=head3 list_priv_grps

  my @grps = $site->list_priv_grps;
  my $grps_aref = $site->list_priv_grps;

Returns a list or array reference of the Bric::Util::Grp::User objects that
are used for granting users permission to access the assets in a site.

B<Note:> Do I<not> change the name, description, or permission associations of
these groups. Those functions are handled internally by Bric::Biz::Site. Just
use these groups to add and remove users you wish to associate with a site.

=cut

sub list_priv_grps {
    my $self = shift;
    my ($id, $old, $new) = $self->_get(qw(id _rename name));
    Bric::Util::Grp::User->list({ description => "__Site $id Users__",
                                  permanent   => 1,
                                  all         => 1 });
}

##############################################################################

=head2 Private Functions

=head3 $set_unique_attr

  sub set_name { $set_unique_attr->('name', @_) }

Used by the accessors for attributes that require a globally-unique value. The
first argument should be the name of the attribute to be set, and the
succeeding values.

B<Throws:>

=over 4

=item Error::NotUnique

=back

=cut

$set_unique_attr = sub {
    my ($field, $self, $value) = @_;

    my $disp = $self->my_meths->{$field}{disp};
    # Make sure we have a value.
    throw_not_unique maketext => ["Value of [_1] cannot be empty", $disp]
      unless $value;

    my $old_value = $self->_get($field);
    # Just succeed if the new value is the same as the old value.
    return $self if $old_value and lc $value eq lc $old_value;

    # Check the database for any existing sites with the new value.
    if ($self->list_ids({ $field => $value })) {
        throw_not_unique error => "Not unique", maketext =>
          ["A site with the [_1] '[_2]' already exists", $disp, $value];
    }

    # Success!
    $self->_set([$field, '_rename'], [$value, $old_value]);
};

##############################################################################

=head3 $get_em

  $get_em->($invocant, $params, $ids_only);

Function used by C<lookup()>, C<list()>, and C<list_ids()> to retrieve
site objects from the database. The arguments are as follows:

=over

=item C<$invocant>

The class name or object that invoked the method call.

=item C<$params>

The hashref of parameters supported by the method and that can be used to
create a SQL search query.

=item C<$ids_only>

A boolean indicating whether to return site objects or site IDs only.

=back

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

$get_em = sub {
    my ($invocant, $params, $ids_only) = @_;
    my $tables = "$TABLE a, member m, site_member c";
    my $wheres = 'a.id = c.object_id AND c.member__id = m.id AND ' .
      'm.active = 1';
    my @params;

    foreach my $k (keys %$params) {
        if ($k eq 'id') {
            # Simple lookup by ID.
            $wheres .= " AND a.id = ?";
            push @params, $params->{$k};
        } elsif ($k eq 'active') {
            # Simple lookup by "active" boolean.
            $wheres .= " AND a.active = ?";
            push @params, $params->{$k} ? 1 : 0;
        } elsif ($k eq 'grp_id') {
            # Look up by group membership.
            $tables .= ", member m2, site_member c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id" .
              " AND m2.active = 1 AND m2.grp__id = ?";
            push @params, $params->{$k};
        } else {
            # Simple string comparison.
            $wheres .= " AND LOWER(a.$k) LIKE ?";
            push @params, lc $params->{$k};
        }
    }

    my ($qry_cols, $order) = $ids_only ? (\'DISTINCT a.id', 'a.id') :
      (\$SEL_COLS, 'a.name, a.id');

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    if ($ids_only) {
        my $ids = col_aref($sel, @params);
        return unless @$ids;
        return wantarray ? @$ids : $ids;
    }

    execute($sel, @params);
    my (@d, @sites, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    my $class = ref $invocant || $invocant;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new site object.
            my $self = $class->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @sites, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }

    return unless @sites;
    return wantarray ? @sites : \@sites;
};

##############################################################################

=head3 $rename_grps

  $get_em->($self);

Looks up the associated user groups in the database and renames them. Used
when the name of the site has changed. Since the permission user groups will
appear in the UI, it makes sense that they always be appropriately named.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

$rename_grps = sub {
    my $self = shift;
    my ($old, $new) = $self->_get(qw(_rename name));
    foreach my $grp ($self->list_priv_grps) {
        (my $name = $grp->get_name) =~ s/^$old/$new/;
        $grp->set_name($name);
        $grp->save;
    }
    $self->_set(['_rename'], []);
};

1;
__END__

##############################################################################

=pod

=end private

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

=over 4

=item L<Bric::Biz::Category|Bric::Biz::Category>

Each category object is associated with a site.

=item L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel>

Each output channel object is associated with a site.

=item L<Bric::Biz::AssetType|Bric::Biz::AssetType>

Each top-level element object is associated with one or more site.

=item L<Bric::Biz::Workflow|Bric::Biz::Workflow>

Each workflow object is associated with a site.

=item L<Bric::Biz::Asset|Bric::Biz::Asset>

Each asseet object is associated with a site.

=item L<Bric::Dist::ServerType|Bric::Dist::ServerType>

Each destination object is associated with a site.

=back

=cut
