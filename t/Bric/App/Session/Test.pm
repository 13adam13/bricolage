package Bric::App::Session::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Apache::FakeRequest;
use Bric::App::Session;

##############################################################################
# Setup for tests.
##############################################################################
sub test_setup : Test(setup => 1) {
    my $self = shift;
    my $r = Apache::FakeRequest->new;
    ok( Bric::App::Session::setup_user_session($r), "Setup user session" );
}

##############################################################################
# Test functions.
##############################################################################
sub test_session : Test(3) {
    my $self = shift;
    my $sess = Bric::App::Session->instance();
    ok( $sess->{foo} = 'bar', "Set foo" );
    is( $sess->{foo}, 'bar', "Test for 'bar'" );
    my $sess2 = Bric::App::Session->instance();
    is( $sess2->{foo}, 'bar', "Test new instance for 'bar'" );
}

##############################################################################
# Bogus Apache::Cookie module for testing.
##############################################################################
package Apache::Cookie;

use strict;
use warnings;
use Bric::Config qw(AUTH_COOKIE);

my %ARGS;

sub new {
    my ($proto, $r, %args) = @_;
    %args = %ARGS unless %args;
    return undef unless %args;
    return bless \%args, ref $proto || $proto;
}

sub fetch { ( AUTH_COOKIE, Apache::Cookie->new(0, %ARGS) ) }
sub value { $_[0]->{-value} }
sub bake { %ARGS = %{$_[0]} }




1;
__END__
