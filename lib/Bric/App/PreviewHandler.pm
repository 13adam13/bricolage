package Bric::App::PreviewHandler;

=head1 NAME

Bric::App::PreviewHandler - Special Apache handlers used for local previewing.

=head1 VERSION

$Revision: 1.14 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.14 $ )[-1];

=head1 DATE

$Date: 2003-03-07 16:34:39 $

=head1 SYNOPSIS

  <Perl>
      if (PREVIEW_LOCAL) {
          $PerlTransHandler = 'Bric::App::PreviewHandler::uri_handler';
          if (PREVIEW_MASON) {
              $PerlFixupHandler = 'Bric::App::PreviewHandler::fixup_handler';
          }
      }
  </Perl>

=head1 DESCRIPTION

This package is the main package used by Apache for managing the Bricolage application.
It loads all the necessary Mason and Bricolage libraries and sets everything up for
use in Apache. It is one function is handler(), which is called by mod_perl for
every request.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Apache::Constants qw(DECLINED OK);
use Bric::Config qw(:prev :err);
use Bric::Util::Trans::FS;
use Apache::Log;

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant ERROR_FILE =>
  Bric::Util::Trans::FS->cat_dir(MASON_COMP_ROOT->[0][1],
			       Bric::Util::Trans::FS->split_uri(ERROR_URI));

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;

# We'll use this to check to seed if the referer is a preview page.
my $prev_qr = do {
    my $prev = $fs->cat_uri('/', PREVIEW_LOCAL);
    qr{[^/]*//[^/]*$prev};
};


################################################################################
# Instance Fields
################################################################################

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

=item my $status = uri_handler()

Handles the URI Translation phase of the Apache request if the PREVIEW_LOCAL
directive is true. Otherwise unused. It's job is to ensure that files requested
directly from the preview directory (/data/preview) as if they were requested
from the document root (/) are directed to the correct file.

B<Throws:> NONE.

B<Side Effects:> This handler will slow Bricolage, as it will be executing a
fair bit of extra code on every request. It is thus recommended to use a
separate server for previews.

B<Notes:> NONE.

=cut

sub uri_handler {
    my $r = shift;
    my $ret = eval {
	# Decline the request unless it's coming from the preview directory.
	{
	    local $^W;
	    return DECLINED unless $r->header_in('referer') =~ m{$prev_qr};
	}
	# Grab the URI and break it up into its constituent parts.
	my $uri = $r->uri;
	my @dirs = $fs->split_uri($uri);
	# Let the request continue if the file exits.
	return DECLINED if -e $fs->cat_dir(MASON_COMP_ROOT->[0][1], @dirs);
	# Let the request continue (with a 404) if the file doesn't exist in the
	# preview directory.
	return DECLINED
	  unless -e $fs->cat_dir(MASON_COMP_ROOT->[0][1], PREVIEW_LOCAL, @dirs);
	# If we're here, it exits inthe preview directory. Point the request to it.
	$r->uri( $fs->cat_uri('/', PREVIEW_LOCAL, $uri) );
	return DECLINED;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

=item my $status = fixup_handler()

Runs after the MIME-checking request phase so that, if the content-type is not
text/html. Only used when both the PREVIEW_LOCAL and PREVIEW_MASON directives
have been set to true, as it will prevent Mason from munging non-Mason files
such as images.

B<Throws:> NONE.

B<Side Effects:> This handler will slow Bricolage, as it will be executing a
fair bit of extra code on every request. It is thus recommended to use a
separate server for previews, or to disable Mason for previews on the Bricolage
server.

B<Notes:> NONE.

=cut

sub fixup_handler {
    my $r = shift;
    my $ret = eval {
	# Start by disabling browser caching.
	$r->no_cache(1);
	# Just return if it's an httpd content type.
	my $ctype = $r->content_type;
	return OK if $ctype =~ /^httpd/;
	# Set the default handler if it's content type is known and it's not
	# text/html.
	$r->handler('default-handler') if $ctype && $ctype ne 'text/html';
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
    # Set the URI and filename for the error element.
    $r->uri(ERROR_URI);
    $r->filename(ERROR_FILE);
    my $msg = 'Error executing PreviewHandler';
    # Set some headers so that the error element can have some error
    # messages to display.
    $r->header_in(BRIC_ERR_MSG => $msg . '.');
    $r->header_in(BRIC_ERR_PAY => $err);
    # Send the error to the apache error log.
    $r->log->error("$msg: $err");
    # Return OK so that Mason can handle displaying the error element.
    return OK;
}

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
