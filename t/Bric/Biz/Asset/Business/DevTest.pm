package Bric::Biz::Asset::Business::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Test::Exception;
use Bric::Biz::Asset::Business;
use Bric::Biz::AssetType;
use Bric::Biz::Person;
use Bric::Util::Grp::Parts::Member::Contrib;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Overrid this method in subclasses.
sub class { 'Bric::Biz::Asset::Business' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( element       => $self->get_elem,
      user__id      => $self->user_id,
      source__id    => 1,
      primary_oc_id => 1,
      site_id       => 100,
    )
}

sub pe {
    my $self = shift;
    diag @_;
    my $at = Bric::Biz::AssetType->lookup({ id => 1 });
    foreach my $oc ($at->get_output_channels) {
        diag $oc->get_name;
    }
}


##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}

##############################################################################
# Constructs a new contributor object.
sub contrib {
    my $self = shift;
    return $self->{contrib} if $self->{contrib};
    my $person = Bric::Biz::Person->new({ lname => 'Wall',
                                          fname => 'Larry' });
    $person->save;

    # Grab the "Writers" group and add Larry.
    my $group = Bric::Util::Grp::Person->lookup({ id => 39 });
    my $member = $group->add_member({ obj => $person });
    $group->save;
    $self->add_del_ids($member->get_id, 'member');
    $self->add_del_ids($person->get_id, 'person');
    return $self->{contrib} = Bric::Util::Grp::Parts::Member::Contrib->lookup
      ({ id => $member->get_id });
}

##############################################################################
# Test output channel associations.
##############################################################################
sub test_oc : Test(36) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
     return "OCs tested only by subclass" if $key eq 'biz';
    ok( my $ba = $self->construct, "Construct $key object" );
    ok( my $elem = $self->get_elem, "Get element object" );

    # Make sure there are the same of OCs yet as in the element.
    ok( my @eocs = $elem->get_output_channels, "Get Element OCs" );
    ok( my @ocs = $ba->get_output_channels, "Get $key OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( scalar @eocs, scalar @ocs, "Check for same number of OCs" );
    is( $eocs[0]->get_id, $ocs[0]->get_id, "Compare for same OC ID" );

    # Save the asset object.
    ok( $ba->save, "Save ST" );
    ok( my $baid = $ba->get_id, "Get ST ID" );
    $self->add_del_ids($baid, $key);

    # Grab the element's first OC.
    ok( my $oc = $eocs[0], "Grab the first OC" );
    ok( my $ocname = $oc->get_name, "Get the OC's name" );

    # Try removing the OC.
    ok( $ba->del_output_channels($oc), "Delete OC from $key" );
    @ocs = $ba->get_output_channels;
    is( scalar @ocs, 0, "No more OCs" );

    # Add the new output channel to the asset.
    ok( $ba->add_output_channels($oc), "Add OC" );
    ok( @ocs = $ba->get_output_channels, "Get OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( $ocs[0]->get_name, $ocname, "Check OC name" );

    # Save it and verify again.
    ok( $ba->save, "Save ST" );
    ok( @ocs = $ba->get_output_channels, "Get OCs again" );
    is( scalar @ocs, 1, "Check for 1 OC again" );
    is( $ocs[0]->get_name, $ocname, "Check OC name again" );

    # Look up the asset in the database and check OCs again.
    ok( $ba = $class->lookup({ id => $baid }), "Lookup $key" );
    ok( @ocs = $ba->get_output_channels, "Get OCs 3" );
    is( scalar @ocs, 1, "Check for 1 OC 3" );
    is( $ocs[0]->get_name, $ocname, "Check OC name 3" );

    # Now check it in and make sure that the OCs are still properly associated
    # with the new version.
    ok( $ba->checkin, "Checkin asset" );
    ok( $ba->save, "Save new version" );
    ok( $ba->checkout({ user__id => $self->user_id }), "Checkout new version" );
    ok( $ba->save, "Save new version" );
    ok( my $version = $ba->get_version, "Get Version number" );
    ok( $ba = $class->lookup({ id => $baid }), "Lookup new version of $key" );
    is( $ba->get_version, $version, "Check version number" );
    ok( @ocs = $ba->get_output_channels, "Get OCs 4" );
    is( scalar @ocs, 1, "Check for 1 OC 4" );
    is( $ocs[0]->get_name, $ocname, "Check OC name 4" );
}

##############################################################################
# Test primary_oc_id property.
##############################################################################
sub test_primary_oc_id : Test(8) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    ok( my $ba = $self->construct( name => 'Flubberman',
                                   slug => 'hugoman'),
        "Construct asset" );
    ok( $ba->save, "Save asset" );

    # Save the ID for cleanup.
    ok( my $id = $ba->get_id, "Get ID" );
    $self->add_del_ids([$id], $key);

    is( $ba->get_primary_oc_id, 1, "Check primary OC ID" );

    # Try list().
    ok( my @bas = $class->list({ primary_oc_id => 1,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
    is( $bas[0]->get_primary_oc_id, 1, "Check for OC ID 1" );
}

##############################################################################
# Test output_channel_id parameter.
##############################################################################
sub test_oc_id : Test(14) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    # Construct a secondary output channel.
    ok ( my $oc = Bric::Biz::OutputChannel->new({ name        => 'Bogus',
                                                  description => 'Bogus OC',
                                                  site_id     => 100,
                                                  protocol    => 'http://',
                                                }),
       "Create bogus OC" );
    ok( $oc->save, "Save bogus OC" );
    ok( my $ocid = $oc->get_id, "Get bogus OC ID" );
    $self->add_del_ids($ocid, 'output_channel' );

    # Construct a new document.
    ok( my $ba = $self->construct( name => 'Flubberman',
                                   slug => 'hugoman'),
        "Construct document" );
    # Add the new output channel to it and save it.
    ok( $ba->add_output_channels($oc), "Add bogus OC" );
    ok( $ba->save, "Save docuument" );

    # Save the ID for cleanup.
    ok( my $id = $ba->get_id, "Get ID" );
    $self->add_del_ids([$id], $key);

    is( $ba->get_primary_oc_id, 1, "Check primary OC ID" );

    # Try output_channel_id parameter to list with primary OC ID.
    ok( my @bas = $class->list({ output_channel_id => 1,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
    is( $bas[0]->get_primary_oc_id, 1, "Check for OC ID 1" );

    # Try output_channel_id parameter to list with secondary OC ID.
    ok( @bas = $class->list({ output_channel_id => $ocid,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
}

##############################################################################
# Test aliasing.
##############################################################################
sub test_alias : Test(33) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
     return "Aliases tested only by subclass" if $key eq 'biz';

    throws_ok { $class->new }
      qr/Cannot create an asset without an element or alias ID/,
      "Check that you cannot create empty stories";

    throws_ok { $class->new({ alias_id => 1, element__id => 1}) }
      qr/Cannot create an asset with both an element and an alias ID/,
      "Check that you cannot create a asset with both element__id and an ".
      "alias";

    throws_ok { $class->new({ alias_id => 1, element => 1}) }
      qr/Cannot create an asset with both an element and an alias ID/,
      "Check that you cannot create a asset with both element and an ".
      "alias";

    ok( my $ba = $self->construct( name => 'Victor',
                                   slug => 'hugo' ),
        'Construct asset');
    ok( $ba->save, "Save asset" );

    # Save the ID for cleanup.
    ok( my $sid = $ba->get_id, "Get ID" );
    $self->add_del_ids($sid);

    ok( $ba = $class->lookup({id => $ba->get_id }), "Reload");

    throws_ok { $class->new({ alias_id => $ba->get_id }) }
      qr /Cannot create an asset without a site/,
      "Check that you need the Site parameter";

    # Create an extra site
    my $site1 = Bric::Biz::Site->new({ name => __PACKAGE__ . "1",
                                       domain_name => __PACKAGE__ . "1" });

    ok( $site1->save, "Create first dummy site");
    my $site1_id = $site1->get_id;
    $self->add_del_ids($site1_id, 'site');

    throws_ok { $class->new({ alias_id => $ba->get_id,
                              site_id => $site1_id }) }
      qr/Cannot create an alias to an asset based on an element that is not associated with this site/,
      "Check that an element needs to be associated with a site ".
      "for a target to aliasable";

    my $element = $ba->_get_element_object();

    $element->add_sites([$site1]);

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name    => __PACKAGE__ . "1",
                                                 site_id => $site1_id }),
        "Create OC" );
    ok( $oc->save, "Save OC" );
    ok( my $ocid = $oc->get_id, "Get OC ID" );
    $self->add_del_ids($ocid, 'output_channel');

    ok( $element->add_output_channels([$ocid]), "Associate OC" );
    ok( $element->set_primary_oc_id($ocid, $site1_id), "Associate primary OC" );
    ok( $element->save, "Save element" );

    ok( my $alias_asset = $class->new({ alias_id => $ba->get_id,
                                        site_id  => $site1_id,
                                        user__id => $self->user_id,
                                      }),
        "Create an alias asset" );

    isnt($alias_asset->_get_element_object, undef,
         "Check that we get an element object");

    is($alias_asset->_get_element_object->get_id,
       $ba->_get_element_object->get_id,
       "Check that alias_asset has an element object");

    if ($class->key_name eq 'story') {
        is($alias_asset->get_slug, $ba->get_slug, "Check slug");
          # Change the slug to ensure it has a unique URI.
        ok( $alias_asset->set_slug('slug'), "Set slug" );

    } else {
      SKIP: {
            skip "No slug on media assets", 1;
        }
    }

    ok( $alias_asset->save , "Try to save it");
    my $alias_id = $alias_asset->get_id;
    $self->add_del_ids($alias_id);
    like($alias_id, qr/^\d+$/, "alias id should be a number");

    ok( $alias_asset = $class->lookup({ id => $alias_id }),
        "Refetch the alias");

    isa_ok($alias_asset, $class,
           "Checking that we got $alias_id back");

    is($alias_asset->get_alias_id, $ba->get_id,
       "Does it still point to the correct asset");

    is_deeply($ba->get_tile, $alias_asset->get_tile,
              "Should get identical tiles");

    is_deeply([$alias_asset->get_all_keywords],
              [$ba->get_all_keywords],
              "Check get_all_keywords");

    is_deeply([$alias_asset->get_keywords],
              [$ba->get_keywords],
              "Check get_keywords");

    is_deeply([$alias_asset->get_contributors],
              [$ba->get_contributors],
              "Check get_contributors");

    ok( $element->remove_sites([$site1]), "Remove site" );
    ok( $element->save, "Save element" );
}

1;
__END__
