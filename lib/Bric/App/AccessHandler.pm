package Bric::App::AccessHandler;

=head1 NAME

Bric::App::AccessHandler - Handles Authentication and Session setup during the
Apache Access phase.

=head1 VERSION

$LastChangedRevision$

=cut

# Grab the Version Number.
INIT {
    require Bric; our $VERSION = Bric->VERSION
}

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  PerlModule Bric::App::AccessHandler    <Location /media>
        SetHandler default-handler
    </Location>

  PerlModule Bric::App::Handler
  PerlFreshRestart    On
  DocumentRoot "/usr/local/bricolage/comp"
  <Directory "/usr/local/bricolage/comp">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
      SetHandler perl-script
      PerlHandler Bric::App::Handler
      PerlAccessHandler Bric::App::AccessHandler
  </Directory>

=head1 DESCRIPTION

This module handles the Access phase of an Apache request. It authenticates
users to Bricolage, and sets up Session handling.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependencies
use Apache::Constants qw(:common :http);
use Apache::Log;
use Bric::App::Session;
use Bric::App::Util qw(:redir :history);
use Bric::App::Auth qw(auth logout);
use Bric::Config qw(:err :ssl :cookies);

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;
my $ssl_port = SSL_PORT == 443 ? '' : ':' . SSL_PORT;

################################################################################

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Functions

=over 4

=item my $status = handler($r)

Sets up the user session and checks authentication. If the authentication is current,
it returns OK and the request continues. Otherwise, it caches the requested URI in
the session and returns FORBIDDEN.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my $r = shift;

    my $ret = eval {
        # Silently zap foolish user access to http when SSL is always required
        # by web master.
        if (ALWAYS_USE_SSL && SSL_ENABLE && LISTEN_PORT == $r->get_server_port) {
            $r->custom_response(FORBIDDEN, 'https://'. $r->hostname .
                                $ssl_port . '/logout');
            return FORBIDDEN;
        }

        # Propagate SESSION and AUTH cookies if we switched server ports
        my %qs = $r->args;
        my %cookies = Apache::Cookie->fetch;
        # work around multiple servers if login event
        if ( exists $qs{&AUTH_COOKIE} && ! $cookies{&AUTH_COOKIE} ) {
            foreach(&COOKIE, &AUTH_COOKIE) {
                if (exists $qs{$_} && $qs{$_}) {
                    # hmmm.... Apache is in @INC or we would not have $r
                    my $cook = Apache::unescape_url($qs{$_});
                    $cookies{$_} = $cook;           # insert / overwrite value
                    # propagate this particular cookie back to the browser with
                    # all properties
                    $r->err_headers_out->add('Set-Cookie',$_ . '=' . $cook);
                }
            }
            my $http_cook = '';
            while(my($k,$v) = each %cookies) {
                # Reconstitute the input cookie
                $http_cook .= '; ' if $http_cook;
                $v = (split('; ',$v))[0];
                $http_cook .= $k .'='. $v;
            }
            $r->header_in('Cookie', $http_cook);
            # Replacement HTTP_COOKIE string
        }
        # Continue, the session is not the wiser about inserted cookies IN.

        # Set up the user's session data.
        Bric::App::Session::setup_user_session($r);
        my ($res, $msg) = auth($r);
        return OK if $res;

        # If we're here, the user needs to authenticate. Figure out where they
        # wanted to go so we can redirect them there after they've logged in.
        $r->log_reason($msg) if $msg;
#       my $uri = $r->uri;
#       my $args = $r->args;
#       $uri = "$uri?$args" if $args;
#       set_redirect($uri);
        # Commented out the above and set the login to always redirect to "/".
        # This is because the session might otherwise get screwed up. The
        # del_redirect() function in Bric::App::Util depends on this
        # knowledge, so if we ever change this, we'll need to make sure we fix
        # that function, too.
#        set_redirect('/');
        my $hostname = $r->hostname;
        if (SSL_ENABLE) {
            $r->custom_response(FORBIDDEN, "https://$hostname$ssl_port/login");
        } else {
            $r->custom_response(FORBIDDEN, "http://$hostname$port/login");
        }
        return FORBIDDEN;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = logout_handler($r)

Logs the user out.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub logout_handler {
    my $r = shift;

    my $ret = eval {
        # Set up the user's session data.
        Bric::App::Session::setup_user_session($r);
        # Logout.
        logout($r);
        # Expire the user's session.
        Bric::App::Session::expire_session($r);

        # Redirect to the login page.
        my $hostname = $r->hostname;
        if (SSL_ENABLE) {
            # if SSL and logging out of server #1, make sure and logout of
            # server #2
            if (scalar $r->args =~ /goodbye/) {
                $r->custom_response(FORBIDDEN,
                                    "https://$hostname$ssl_port/login");
            } elsif ($r->get_server_port == &SSL_PORT) {
                $r->custom_response(HTTP_MOVED_TEMPORARILY,
                                    "http://$hostname$port/logout?goodbye");
                return HTTP_MOVED_TEMPORARILY;
            } else {
                $r->custom_response(HTTP_MOVED_TEMPORARILY,
                                    "https://$hostname$ssl_port/logout?goodbye");
                return HTTP_MOVED_TEMPORARILY;
            }
        } else {
            $r->custom_response(FORBIDDEN, "http://$hostname$port/login");
        }
        return FORBIDDEN;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = okay($r)

This handler should B<only> be used for the '/login' location of the SSL virtual
host. It simply sets up the user session and returns OK.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub okay {
    my $r = shift;
    my $ret = eval {
        # Set up the user's session data.
        Bric::App::Session::setup_user_session($r);
        return OK;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = handle_err($r, $err)

Handles errors for the other handlers in this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handle_err {
    my ($r, $err) = @_;
    # Set the filename for the error element.
    my $uri = $r->uri;
    (my $fn = $r->filename) =~ s/$uri/${\ERROR_URI}/;
    $r->uri(ERROR_URI);
    $r->filename($fn);

    $err = Bric::Util::Fault::Exception::AP->new(
        error => 'Error executing AccessHandler',
        payload => $err,
    );
    $r->pnotes('BRIC_EXCEPTION' => $err);

    # Send the error to the apache error log.
    $r->log->error($err->as_text());
    # Return OK so that Mason can handle displaying the error element.
    return OK;
}

################################################################################

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

L<Bric|Bric>

=cut
