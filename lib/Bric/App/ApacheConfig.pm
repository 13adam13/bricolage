package Bric::App::ApacheConfig;

=head1 NAME

Bric::App::ApacheConfig - Bricolage httpd.conf configuration

=head1 VERSION

$Revision$

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision$ )[-1];

=head1 DATE

$Date$

=head1 SYNOPSIS

  <Perl>
      use File::Spec::Functions qw(catdir);
      BEGIN {
        $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
        unshift(@INC, catdir($ENV{BRICOLAGE_ROOT}, 'lib'));
      };
  </Perl>
  PerlModule Bric::App::ApacheConfig

=head1 DESCRIPTION

This module takes care of all of Apache configuration necessary to get Bricolage
working. Putting it all in this module makes it easier for you to add it to your
own httpd.conf by using only a single line.

=begin comment

Right now, of course, the <Perl> section shown in the synopsis above in order to
make sure that the path to the Bric libraries is in Perl's @INC path. But maybe
we ought to start putting them into the default @INC rather than adding their
directory to @INC by using Makefile.PL. Just a thought.

=end comment

=cut

use strict;
use Bric::App::ApacheStartup;
use Bric::Constant qw(:ui);
use constant DEBUGGING => 0;

do {
    my $names = 'NameVirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT . "\n";

    # Set up the basic configuration. Default to UTF-8 (it can be overridden
    # on a per-request basis in Bric::App::Handler.
    my @config = (
        '  DocumentRoot           ' . MASON_COMP_ROOT->[0][1],
        '  ServerName             ' . VHOST_SERVER_NAME,
        "  DefaultType            \"text/html; charset=utf-8\"",
        "  AddDefaultCharset      utf-8",
        '  SetHandler             perl-script',
        '  PerlHandler            Bric::App::Handler',
        '  PerlAccessHandler      Bric::App::AccessHandler',
        '  PerlCleanupHandler     Bric::App::CleanupHandler',
        '  RedirectMatch          '.
                'permanent .*\/favicon\.ico$ /media/images/favicon.ico',
    );

    # Setup Apache::DB handler if debugging
    push @config, '  PerlFixupHandler       Apache::DB' if DEBUGGING;

    # see Apache::SizeLimit manpage
    push @config, '  PerlFixupHandler       Apache::SizeLimit'
      if CHECK_PROCESS_SIZE;

    # This will slow down every request; thus we recommend that previews
    # not be local.
    push @config,
      '  PerlTransHandler       Bric::App::PreviewHandler::uri_handler'
      if PREVIEW_LOCAL;

    # This URI will handle logging users out.
    my @locs = (
        "  <Location /logout>\n" .
        "    PerlAccessHandler   Bric::App::AccessHandler::logout_handler\n" .
        "    PerlCleanupHandler  Bric::App::CleanupHandler\n" .
        "  </Location>"
    );

    # Mask off Apache::DB handler if debugging - the debugger
    # seems to cause problems for login for some reason.  With the
    # Apache::DB handler in place the output from the first screen
    # after login goes to the debugger's STDOUT instead of the
    # browser!
    my $fix = DEBUGGING
      ? "\n    PerlFixupHandler    Apache::OK"
      : '';

    # This URI will handle logging users in.
    push @locs,
      "  <Location /login>\n" .
      "    SetHandler          perl-script\n" .
      "    PerlAccessHandler   Bric::App::AccessHandler::okay\n" .
      "    PerlHandler         Bric::App::Handler\n" .
      "    PerlCleanupHandler  Bric::App::CleanupHandler$fix\n" .
      "  </Location>";

    # We might need to change this for SSL configuration.
    my $loginref = \$locs[-1];

    # This URI will handle all non-Mason stuff that we server (graphics, etc.).
    push @locs,
      "  <Location /media>\n" .
      "    SetHandler          default-handler\n" .
      "    PerlAccessHandler   Apache::OK\n" .
      "    PerlCleanupHandler  Apache::OK$fix\n" .
      "  </Location>";

    # Force JavaScript to the proper MIME type and always use Unicode.
    push @locs,
      "  <Location /media/js>\n" .
      "    ForceType           \"application/x-javascript; charset=utf-8\"\n" .
      "  </Location>";

    # Force CSS to the proper MIME type.
    push @locs,
      "  <Location /media/css>\n" .
      "    ForceType           \"text/css\"\n" .
      "  </Location>";

    # Enable CGI for htmlarea spellchecker.
    if (ENABLE_HTMLAREA){
        push @locs,
          "  <Location /media/htmlarea/plugins/SpellChecker>\n" .
          "    SetHandler None\n" .
          "    AddHandler perl-script .cgi\n" .
          "    PerlHandler Apache::Registry\n" .
          "  </Location>";
    }

    # This will serve media assets and previews.
    push @locs,
      "  <Location /data>\n" .
      "    SetHandler          default-handler\n" .
      "  </Location>";

    # This will run the SOAP server.
    push @locs,
      "  <Location /soap>\n" .
      "    SetHandler          perl-script\n" .
      "    PerlHandler         Bric::SOAP::Handler\n" .
      "   PerlAccessHandler    Apache::OK\n" .
      "  </Location>";

    if (ENABLE_DIST) {
        push @locs,
          "  <Location /dist>\n" .
          "    SetHandler          perl-script\n" .
          "    PerlHandler         Bric::Dist::Handler\n" .
          "  </Location>";
    }

    if (QA_MODE) {
        # Turn on Perl warnings and run Apache::Status.
        push @config, '  PerlWarn               On';
        push @locs,
          "  <Location /perl-status>\n" .
          "    SetHandler          perl-script\n" .
          "    PerlHandler         Apache::Status\n" .
          "    PerlAccessHandler   Apache::OK\n" .
          "    PerlCleanupHandler  Apache::OK$fix\n" .
          "  </Location>";
    }

    if (PREVIEW_LOCAL) {
        my $prev_loc = "/" . join('/', PREVIEW_LOCAL);
        if (PREVIEW_MASON) {
            # We need to take some special steps to ensure that Mason properly
            # handles the request.
            push @locs,
              "  <Location $prev_loc>\n" .
              "    SetHandler          perl-script\n" .
              "    PerlFixupHandler    Bric::App::PreviewHandler::fixup_handler\n" .
              "    PerlHandler         Bric::App::Handler\n" .
              "  </Location>";
        } else {
            # This will ensure that the documents are not cached by the browser, so
            # that the preview will always serve the most recently burned file.
            push @locs,
              "  <Location $prev_loc>\n" .
              "    PerlFixupHandler    " .
                   qq{"sub { \$_[0]->no_cache(1); return Apache::OK; }"\n} .
              "  </Location>";
        }
    }

    my $config = join "\n",
      "<VirtualHost " . NAME_VHOST . ':' . LISTEN_PORT . ">",
        @config, @locs,
      '</VirtualHost>';

    if (SSL_ENABLE) {
        $names .=  'NameVirtualHost ' . NAME_VHOST . ':' . SSL_PORT . "\n";
        push @config,
            '  SSLCertificateFile     ' . SSL_CERTIFICATE_FILE,
            '  SSLCertificateKeyFile  ' . SSL_CERTIFICATE_KEY_FILE;

        # Replace the login location.
        $loginref =
          "<Location /login>\n" .
          "    SetHandler         perl-script\n" .
          "    PerlAccessHandler  Bric::App::AccessHandler::okay\n" .
          "    PerlHandler        Bric::App::Handler\n" .
          "    PerlCleanupHandler Bric::App::CleanupHandler\n" .
          "  </Location>";

        # Apache::ReadConfig does not handle <IfModule>
        if (MANUAL_APACHE) {
            if (SSL_ENABLE eq 'apache_ssl') {
                push @config,
                  '  SSLEnable',
                  '  SSLRequireSSL',
                  '  SSLVerifyClient        0',
                  '  SSLVerifyDepth         10';
            } else {
                # is mod_ssl
                push @config, '  SSLEngine              On';
            }
        } else {
            push @config,
              "  <IfModule mod_ssl.c>\n" .
              "    SSLEngine           On\n" .
              "  </IfModule>\n" .
              "  <IfModule apache_ssl.c>\n" .
              "    SSLEnable\n" .
              "    SSLVerifyClient     0\n" .
              "    SSLVerifyDepth      10\n" .
              "    SSLRequireSSL\n" .
              "  </IfModule>";
        }

        $config .= join "\n", '',
          "<VirtualHost " . NAME_VHOST . ':' . SSL_PORT . ">",
            @config, @locs,
          '</VirtualHost>';
    }

    if (MANUAL_APACHE) {
        # Write out a configuration file and include it.
        use Bric::Util::Trans::FS;
        my $conffile = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage',
                                                      'bric_httpd.conf');
        open CONF, ">$conffile" or die "Cannot open $conffile for output: $!\n";
        print CONF $names, $config;
        close CONF;

        # Place Include directive in Apache's scope
        package Apache::ReadConfig;
        our $Include = $conffile;
    } else {
        # place VirtualHost stuff in Apache's scope
        package Apache::ReadConfig;
        our $PerlConfig = $names . $config;
    }
};

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut
