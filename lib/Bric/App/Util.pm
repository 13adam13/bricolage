package Bric::App::Util;
###############################################################################

=head1 NAME

Bric::App::Util - A class to house general application functions.

=head1 VERSION

$Revision: 1.33 $

=cut

our $VERSION = (qw$Revision: 1.33 $ )[-1];

=head1 DATE

$Date: 2004-05-05 02:27:05 $

=head1 SYNOPSIS

  use Bric::App::Util;

=head1 DESCRIPTION

Utility functions.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programmatic Dependencies
#use CGI::Cookie;
#use Bric::Config qw(:qa :cookies);
use Bric::App::Session qw(:state :user);
use Bric::Config qw(:cookies :mod_perl);
use Bric::Util::Class;
use Bric::Util::Pref;
use Apache;
use Apache::Request;
use HTML::Mason::Request;
use Apache::Constants qw(HTTP_OK);
use Apache::Util qw(escape_html);
use HTTP::BrowserDetect;
use Bric::Util::Language;
use Bric::Util::Fault qw(throw_gen);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Exporter );

our @EXPORT_OK = qw(
                    add_msg
                    get_msg
                    next_msg
                    num_msg
                    clear_msg

                    get_pref

                    get_package_name
                    get_class_info
                    get_disp_name
                    get_class_description

                    set_redirect
                    get_redirect
                    del_redirect
                    do_queued_redirect
                    redirect
                    redirect_onload

                    log_history
                    last_page
                    pop_page

                    mk_aref

                    detect_agent
                    parse_uri
                    status_msg
                    severe_status_msg
                   );

our %EXPORT_TAGS = (all     => \@EXPORT_OK,
                    msg     => [qw(add_msg
                                   get_msg
                                   next_msg
                                   num_msg
                                   clear_msg)],
                    redir   => [qw(set_redirect
                                   get_redirect
                                   del_redirect
                                   do_queued_redirect
                                   redirect
                                   redirect_onload)],
                    history => [qw(log_history
                                   last_page
                                   pop_page)],
                    pref    => ['get_pref'],
                    pkg     => [qw(get_package_name
                                   get_disp_name
                                   get_class_description
                                   get_class_info)],
                    aref    => ['mk_aref'],
                    browser => [qw(detect_agent
                                   parse_uri
                                   status_msg
                                   severe_status_msg)],
                   );

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;
use constant DEBUG_COOKIE => 'BRICOLAGE_DEBUG';

use constant MAX_HISTORY => 10;

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $login_marker = LOGIN_MARKER .'='. LOGIN_MARKER;

#------------------------------------------------------------------------------#

#--------------------------------------#
# Instance Fields

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

NONE

=cut

#--------------------------------------#

=head2 Destructors

=cut

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item (1 || undef) = add_msg($txt)

Add a new warning message to the current list of messages.

B<Throws:>

NONE

B<Side Effects:> Adds the message to the session.

B<Notes:>

NONE

=cut

sub add_msg {
    return unless @_;
    my $session = Bric::App::Session->instance;
    my $msg = $session->{_msg} ||= [];
    my $lang = Bric::Util::Language->instance;
    push @$msg, $lang->maketext(@_);
}

#------------------------------------------------------------------------------#

=item $txt = get_msg($num)

=item (@txt_list || $txt_list) = get_msg()

Return warning message number '$num' or if $num is not given return all error
messages.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_msg {
    my ($num) = @_;
    my $msg = Bric::App::Session->instance->{'_msg'};

    if (defined $num) {
        return $msg->[$num];
    } else {
        return wantarray ? @$msg : $msg;
    }
}

#------------------------------------------------------------------------------#

=item ($txt || undef) = next_msg

Returns the next warning message in the list.  If there are no more messages,
it will return undef.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub next_msg {
    my $session = Bric::App::Session->instance();
    my $msg = $session->{'_msg'};
    my $txt = shift @$msg;
    $session->{'_msg'} = $msg;
    return $txt;
}

#------------------------------------------------------------------------------#

=item $num = num_msg

Returns the current number of warning messages.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub num_msg {
    my $msg = Bric::App::Session->instance->{'_msg'};
    return scalar @$msg;
}

#------------------------------------------------------------------------------#

=item clear_msg

Clears out all the error messages remaining.  This should be called after all
messages have been processed.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub clear_msg {
    Bric::App::Session->instance->{'_msg'} = [];
}

#------------------------------------------------------------------------------#

=item my $aref = mk_aref($arg)

Returns an array reference. If $arg is an anonymous array, it is simply
returned. If it's a defined scalar, it's returned as the single value in an
anonymous array. If it's undef, an empty anonymous array will be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub mk_aref { ref $_[0] ? $_[0] : defined $_[0] ? [$_[0]] : [] }

#------------------------------------------------------------------------------#

=item my $value = get_pref($pref_name)

Returns a preference value.

B<Throws:>

=over 4

=item *

Unable to instantiate preference cache.

=item *

Unable to populate preference cache.

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

=item *

Unable to get cache value.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Pref->lookup_val() internally.

=cut

sub get_pref {
    my $pref_name = shift;

    my $user = get_user_object;

    if ($user) {
        return $user->get_pref($pref_name);
    } else {
        my $pref = Bric::Util::Pref->lookup({ name => $pref_name });
        return $pref->get_value();
    }
}

#------------------------------------------------------------------------------#

=item my $pkg = get_package_name

Returns the package name given a short name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_disp_name { get_class_info($_[0])->get_disp_name }

sub get_package_name { get_class_info($_[0])->get_pkg_name }

sub get_class_description { get_class_info($_[0])->get_description }

sub get_class_info {
    my $key = shift;
    my $class = Bric::Util::Class->lookup({ id => $key, key_name => $key,
                                          pkg_name => $key })
      || throw_gen(error => "No such class key '$key'.");
    return $class;
}


#------------------------------------------------------------------------------#

=item (1 || 0) = set_redirect($loc)

=item $loc     = get_redirect

=item $loc     = del_redirect

Get/Set/Delete a redirect to happen during the next page load that includes the
'header.mc' header element.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

This only works with pages that use the 'header.mc' element.

=cut

sub set_redirect {
    Bric::App::Session->instance->{_redirect} = shift;
}

# Unused as of 1.2.2
sub get_redirect {
    Bric::App::Session->instance->{_redirect};
}

sub del_redirect {
    my $session = Bric::App::Session->instance();
    my $rv = delete $session->{_redirect};
    # Behave normally if not login
    return $rv unless defined $rv and $rv =~ /$login_marker/o;

    # Work-around to allow multi port http / https operation by propagating
    # cookies to 2nd server build hash of cookies from blessed reference into
    # Apache::Tables
    my %cookies;
    my $r = Apache::Request->instance(Apache->request);
    $r->err_headers_out->do(sub {
        my($k,$v) = @_;     # foreach key matching Set-Cookie
        ($k,$v) = split('=',$v,2);
        $cookies{$k} = $v;
        1;
    }, 'Set-Cookie');

    # get the current authorization cookie
    return $rv unless $cookies{&AUTH_COOKIE};
    my $qsv = AUTH_COOKIE .'='. URI::Escape::uri_escape($cookies{&AUTH_COOKIE});
    # Add current session ID which should not need to be escaped. For now, the
    # path is always "/", since that's what AccessHandler sets it to. If that
    # changes in the future, we'll need to change it here, too, by adding code
    # to attach the proper query string to the URI.
    $qsv .= '&'. COOKIE .'='. $session->{_session_id} .
        URI::Escape::uri_escape('; path=/');
    $rv =~ s/$login_marker/$qsv/;
    return $rv;
}

#------------------------------------------------------------------------------#

=item (1 || 0) = do_queued_redirect

If there is a redirected set, then redirect the browser, otherwise return.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub do_queued_redirect {
    my $loc = del_redirect() || return;
    redirect($loc);
}


#------------------------------------------------------------------------------#

=item (1 || 0) = redirect

Redirect to a different location.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub redirect {
    my $loc = shift or return;
    HTML::Mason::Request->instance->redirect($loc);
}


#------------------------------------------------------------------------------#

=item (1 || 0) = redirect_onload()

  redirect('/');
  redirect('/', $cbh);

Uses a JavaScript function call to redirect the browser to a different
location. Will not clear out the buffer first, so stuff sent ahead will still
draw in the browser. If a Params::Callback object is passed in as the second
argument, the Apache request object will be used to send the JavaScript to the
Browser and the callback handler object will be used to abort the request.
Otherwise, the Mason request object will be used to send the JavaScript to the
browser and to abort the request.

B<Throws:> NONE.

B<Side Effects:> Becuase C<redirect_onload()> executes immediately, if it is
called from a callback, note that no further callbacks will be executed, not
even post-callback request callbacks.

B<Notes:> NONE.

=cut

sub redirect_onload {
    my $loc = shift or return;
    my $js = qq{<script>location.href='$loc';</script>\n};

    if (my $m = HTML::Mason::Request->instance) {
        # Use the Mason request object.
        $m->clear_buffer;
        $m->print($js);
        $m->abort;
    } elsif (my $cbh = shift) {
        # Use the callback handler object.
        my $r = $cbh->apache_req;
        $r->send_http_header unless $r->header_out("Content-type");
        $r->print($js);
        $cbh->abort;
    } else {
        throw_gen "No way to send redirect to browser";
    }
}

=item status_msg($msg)

=item severe_status_msg($msg)

Sometimes there's a long process executing, and you want to send status
messages to the browser so that the user knows what's happening. These
functions will do this for you. Call C<status_msg()> each time you want to
send a status messages, and it'll take care of the rest for you. The
C<severe_status_msg()> will do the same, but convert the message into a red,
bold-fased message before sending it to the browser. When you're done sending
status messages, you can either redirect to another page, or simply finish
drawing the current page. It will draw in below the status messages. This
function will work both in callbacks and in Mason UI code.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub status_msg {
    if (MOD_PERL) {
        _send_msg(escape_html(Bric::Util::Language->instance->maketext(@_)));
    } else {
        print STDERR Bric::Util::Language->instance->maketext(@_);
    }
 }

sub severe_status_msg {
    if (MOD_PERL) {
    _send_msg('<font color="red"><b>' .
              escape_html(Bric::Util::Language->instance->maketext(@_)) .
              "</b></font>");
    } else {
        print STDERR "##################################################\n\n";
        print STDERR Bric::Util::Language->instance->maketext(@_), "\n";
        print STDERR "##################################################\n\n";
    }
}

sub _send_msg {
    my $msg = shift;
    my $key = '_status_msg_';
    my $space = '&nbsp;' x 20;

    if (my $m = HTML::Mason::Request->instance) {
        my $r = $m->apache_req;
        my $old_autoflush = $m->autoflush;   # autoflush is restored below
        $m->autoflush(1);
        unless ( $r->pnotes($key) ) {
            # We haven't called this thing yet. Throw up some initial information.
            $m->print("<br />\n" x 2);
            $r->pnotes($key, 1);
        }

        $m->print(qq{$space<span class="errorMsg">$msg</span><br />\n});

        $m->flush_buffer;
        $m->autoflush($old_autoflush);
    }
}

#------------------------------------------------------------------------------#

=item log_history($args)

Log the current URL for historical purposes.

B<Throws:>

NONE

B<Side Effects:>

Populates the history key of the session data.

B<Notes:>

NONE

=cut

sub log_history {
    my $session = Bric::App::Session->instance();
    my $history = $session->{'_history'};

    my $r = Apache::Request->instance(Apache->request);
    my $curr = $r->uri;

    # Only push this URI onto the stack if it is different than the top value
    if (!$history->[0] || $curr ne $history->[0]) {
        # Push the current URI onto the stack.
        unshift @$history, $curr;

        # Pop the last item off the list if we've grown beyond our max.
        pop @$history if scalar(@$history) > MAX_HISTORY;

        # Save the history back.
        $session->{'_history'} = $history;
    }
}

#------------------------------------------------------------------------------#

=item $uri = last_page($n);

Grab the $n-th page visited.  Argument $n defaults to 1, or the very last page
(A $n value of 0 is the current page).  Only MAX_HISTORY pages are saved.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub last_page {
    my ($n) = @_;

    # Default to one page prior (index 0 contains the current page).
    $n = 1 unless defined $n;

    return Bric::App::Session->instance->{'_history'}->[$n];
}

#------------------------------------------------------------------------------#

=item $uri = pop_page;

Grab the $n-th page visited.  Argument $n defaults to 1, or the very last page
(A $n value of 0 is the current page).  Only MAX_HISTORY pages are saved.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub pop_page {
    my $sess = Bric::App::Session->instance;
    my $hist = $sess->{_history};
    my $ret = shift @$hist;
    $sess->{_history} = $hist;
    return $ret;
}

#------------------------------------------------------------------------------#

=item ($section, $mode, $type, ...) = parse_uri($uri);

Returns $section (e.g. admin), $mode (e.g. manager, profile)
and $type (e.g. user, media, etc). This is centralized here in case
it becomes a complicated thing to do. And, centralizing is nice.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Was comp/lib/util/parseUri.mc.

=cut

sub parse_uri {
    my $uri = shift;
    return split /\//, substr($uri, 1);
}

#--------------------------------------#

=item $href = detect_agent;

Returns an HTTP::BrowserDetect object. The object is cached
for efficiency.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Was comp/widgets/util/detectAgent.mc

=cut

sub detect_agent {
    my $ua = get_state_data('util', 'user-agent');
    if ($ua) {
        return $ua;
    } else {
        $ua = HTTP::BrowserDetect->new;
        set_state_data('util', 'user-agent', $ua);
        return $ua;
    }
}

#--------------------------------------#

=back

=head2 Public Instance Methods

NONE

=cut

#==============================================================================#

=head2 Private Methods

NONE

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut


#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb <garth@perijove.com>
David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<perl>, L<Bric>

=cut
