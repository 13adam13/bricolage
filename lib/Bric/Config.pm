package Bric::Config;
################################################################################

=head1 NAME

Bric::Config - A class to hold configuration settings.

=head1 VERSION

$Revision: 1.50.2.1 $

=cut

our $VERSION = (qw$Revision: 1.50.2.1 $ )[-1];

=head1 DATE

$Date: 2002-10-15 21:57:36 $

=head1 SYNOPSIS

  # import all configuration constants
  use Bric::Config qw(:all);

  if (CONFIG_VARIABLE) { ... }

=head1 DESCRIPTION

Provides access to configuration variables set in conf/bricolage.conf.
See L<Bric::Admin|Bric::Admin> for the list of configuration variables
and their use.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;
use Carp;

#--------------------------------------#
# Programmatic Dependencies
use File::Spec::Functions qw(catdir tmpdir);
use Apache::ConfigFile;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Exporter);

our @EXPORT_OK = qw(DBD_PACKAGE
                    DB_NAME
                    DB_HOST
                    DB_PORT
                    DBD_TYPE
                    DBI_USER
                    DBI_PASS
                    DBI_DEBUG
                    DBI_CALL_TRACE
                    DBI_PROFILE
                    MASON_COMP_ROOT
                    MASON_DATA_ROOT
                    MASON_ARGS_METHOD
                    FIELD_INDENT
                    SYS_USER
                    SYS_GROUP
                    SERVER_WINDOW_NAME
                    NO_TOOLBAR
                    APACHE_BIN
                    APACHE_CONF
                    PID_FILE
                    LISTEN_PORT
                    NAME_VHOST
                    VHOST_SERVER_NAME
                    ALWAYS_USE_SSL
                    SSL_ENABLE
                    SSL_PORT
                    SSL_CERTIFICATE_FILE
                    SSL_CERTIFICATE_KEY_FILE
                    CHAR_SET
                    AUTH_TTL
                    AUTH_SECRET
                    AUTH_COOKIE
                    COOKIE
                    LOGIN_MARKER
                    QA_MODE
                    TEMPLATE_QA_MODE
                    ADMIN_GRP_ID
                    PASSWD_LENGTH
                    LOGIN_LENGTH
                    ERROR_URI
                    ENABLE_DIST
                    DIST_ATTEMPTS
                    MEDIA_URI_ROOT
                    DEF_MEDIA_TYPE
                    ENABLE_SFTP_MOVER
                    MEDIA_FILE_ROOT
                    SMTP_SERVER
                    ALERT_FROM
                    ALERT_TO_METH
                    BURN_ROOT
                    STAGE_ROOT
                    PREVIEW_ROOT
                    BURN_COMP_ROOT
                    BURN_DATA_ROOT
                    BURN_ARGS_METHOD
                    TEMPLATE_BURN_PKG
                    INCLUDE_XML_WRITER
                    XML_WRITER_ARGS
                    ISO_8601_FORMAT
                    PREVIEW_LOCAL
                    PREVIEW_MASON
                    FULL_SEARCH
                    DEFAULT_FILENAME
                    DEFAULT_FILE_EXT
                    ENABLE_FTP_SERVER
                    FTP_PORT
                    FTP_ADDRESS
                    FTP_LOG
                    FTP_DEBUG
                    DISABLE_NAV_LAYER
                    TEMP_DIR
                    PROFILE
                    CHECK_PROCESS_SIZE
                    MAX_PROCESS_SIZE
                    CHECK_FREQUENCY
                    MIN_SHARE_SIZE
                    MAX_UNSHARED_SIZE
                    MANUAL_APACHE
                   );

our %EXPORT_TAGS = (all       => \@EXPORT_OK,
                    cookies   => [qw(AUTH_COOKIE
                                     COOKIE
                                     LOGIN_MARKER)],
                    dbi       => [qw(DBD_PACKAGE
                                     DB_NAME
                                     DB_HOST
                                     DB_PORT
                                     DBD_TYPE
                                     DBI_USER
                                     DBI_PASS
                                     DBI_DEBUG
                                     DBI_CALL_TRACE
                                     DBI_PROFILE)],
                    mason     => [qw(MASON_COMP_ROOT
                                     MASON_DATA_ROOT
                                     MASON_ARGS_METHOD)],
                    burn      => [qw(BURN_ROOT
                                     STAGE_ROOT
                                     PREVIEW_ROOT
                                     BURN_COMP_ROOT
                                     BURN_DATA_ROOT
                                     TEMPLATE_BURN_PKG
                                     DEFAULT_FILENAME
                                     INCLUDE_XML_WRITER
                                     XML_WRITER_ARGS
                                     DEFAULT_FILE_EXT
                                     BURN_ARGS_METHOD)],
                    oc        => [qw(DEFAULT_FILENAME
                                     DEFAULT_FILE_EXT)],
                    sys_user  => [qw(SYS_USER
                                     SYS_GROUP)],
                    auth      => [qw(AUTH_TTL
                                     AUTH_SECRET)],
                    auth_len  => [qw(PASSWD_LENGTH
                                     LOGIN_LENGTH)],
                    prev      => [qw(PREVIEW_LOCAL
                                     STAGE_ROOT
                                     PREVIEW_ROOT
                                     MASON_COMP_ROOT
                                     PREVIEW_MASON)],
                    dist      => [qw(ENABLE_DIST
                                     ENABLE_SFTP_MOVER
                                     DEF_MEDIA_TYPE
                                     DIST_ATTEMPTS
                                     PREVIEW_LOCAL)],
                    qa        => [qw(QA_MODE 
                                     TEMPLATE_QA_MODE)],
                    err       => [qw(ERROR_URI)],
                    char      => [qw(CHAR_SET)],
                    ui        => [qw(FIELD_INDENT
                                     DISABLE_NAV_LAYER
                                     SERVER_WINDOW_NAME
                                     NO_TOOLBAR)],
                    email     => [qw(SMTP_SERVER)],
                    admin     => [qw(ADMIN_GRP_ID)],
                    time      => [qw(ISO_8601_FORMAT)],
                    alert     => [qw(ALERT_FROM
                                     ALERT_TO_METH)],
                    apachectl => [qw(APACHE_BIN
                                     APACHE_CONF
                                     PID_FILE
                                     SSL_ENABLE)],
                    ssl       => [qw(SSL_ENABLE
                                     SSL_PORT
                                     ALWAYS_USE_SSL
                                     LISTEN_PORT)],
                    conf      => [qw(SSL_ENABLE
                                     SSL_CERTIFICATE_FILE
                                     SSL_CERTIFICATE_KEY_FILE
                                     SSL_PORT
                                     LISTEN_PORT
                                     ENABLE_DIST
                                     NAME_VHOST
                                     VHOST_SERVER_NAME
                                     MASON_COMP_ROOT
                                     PREVIEW_LOCAL
                                     PREVIEW_MASON
                                     MANUAL_APACHE)],
                    media     => [qw(MEDIA_URI_ROOT
                                     MEDIA_FILE_ROOT)],
                    search    => [qw(FULL_SEARCH)],
                    ftp       => [qw(ENABLE_FTP_SERVER
                                     FTP_PORT
                                     FTP_ADDRESS
                                     FTP_LOG
                                     FTP_DEBUG)],
                    temp      => [qw(TEMP_DIR)],
                    profile   => [qw(PROFILE)],
                    proc_size => [qw(CHECK_PROCESS_SIZE
                                     MAX_PROCESS_SIZE
                                     CHECK_FREQUENCY
                                     MIN_SHARE_SIZE
                                     MAX_UNSHARED_SIZE)],
                   );

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#
{
    # We'll store the settings loaded from the configuration file here.
    my ($config, $aconf);

    BEGIN {
        # Load the configuration file, if it exists.
        my $conf_file = $ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage';
        $conf_file = catdir($conf_file, 'conf', 'bricolage.conf');
        if (-e $conf_file) {
            open CONF, $conf_file or croak "Cannot open $conf_file: $!\n";
            while (<CONF>) {
                # Get each configuration line into $config.
                chomp;                  # no newline
                s/#.*//;                # no comments
                s/^\s+//;               # no leading white
                s/\s+$//;               # no trailing white
                next unless length;     # anything left?

                # Get the variable and its value.
                my ($var, $val) = split(/\s*=\s*/, $_, 2);

                # Check that the line is a valid config line and exit
                # immediately if not.
                unless (defined $var and length $var and 
                        defined $val and length $val) {
                  print STDERR "Syntax error in $conf_file at line $.: '$_'\n";
                  exit 1;
                }

                # Save the configuration directive.
                $config->{uc $var} = $val;
            }
            close CONF;

            # Set the default VHOST_SERVER_NAME.
            $config->{VHOST_SERVER_NAME} ||= '_default_';

            # Set up the server window name (because Netscape is retarted!).
            ($config->{SERVER_WINDOW_NAME} =
             $config->{VHOST_SERVER_NAME} || '_default_') =~ s/\W+/_/g;

        }
        # Process boolean directives here. These default to 1.
        foreach (qw(ENABLE_DIST PREVIEW_LOCAL NO_TOOLBAR)) {
            my $d = exists $config->{$_} ? lc($config->{$_}) : '1';
            $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
        }
        # While these default to 0.
        foreach (qw(PREVIEW_MASON FULL_SEARCH INCLUDE_XML_WRITER MANUAL_APACHE
                    DISABLE_NAV_LAYER QA_MODE TEMPLATE_QA_MODE DBI_PROFILE
                    PROFILE CHECK_PROCESS_SIZE ENABLE_SFTP_MOVER ALWAYS_USE_SSL))
        {
            my $d = exists $config->{$_} ? lc($config->{$_}) : '0';
            $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
        }

        # Special case for the SSL_ENABLE configuration directive.
        if (my $ssl = lc $config->{SSL_ENABLE}) {
            if ($ssl eq 'off' or $ssl eq 'no') {
                $config->{SSL_ENABLE} = 0;
            } else {
                croak "Invalid SSL_ENABLE directive: '$ssl'"
                  unless $ssl eq 'mod_ssl' or $ssl eq 'apache_ssl';
            }
        } else {
            $config->{SSL_ENABLE} = 0;
        }

        # Set the Mason component root to its default here.
        $config->{MASON_COMP_ROOT} ||=
          catdir($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'comp');

        # Grab the Apache configuration file.
        $config->{APACHE_CONF} ||= '/usr/local/apache/conf/httpd.conf';
        {
            # Apache::ConfigFile can be very noisy in the presence of
            # <Perl> blocks.
            local $^W = 0;
            $aconf = Apache::ConfigFile->new(file => $config->{APACHE_CONF},
                                             ignore_case => 1);
        }
    }

    # Apache Settings.
    use constant MANUAL_APACHE           => $config->{MANUAL_APACHE};
    use constant SERVER_WINDOW_NAME      => $config->{SERVER_WINDOW_NAME};
    use constant NO_TOOLBAR              => $config->{NO_TOOLBAR};

    use constant APACHE_BIN              => $config->{APACHE_BIN}
      || '/usr/local/apache/bin/httpd';
    use constant APACHE_CONF             => $config->{APACHE_CONF};

    use constant PID_FILE                => $aconf->pidfile
      || '/usr/local/apache/logs/httpd.pid';

    use constant LISTEN_PORT             => $config->{LISTEN_PORT} || 80;
    use constant NAME_VHOST              => $config->{NAME_VHOST} || '*';
    use constant VHOST_SERVER_NAME       => $config->{VHOST_SERVER_NAME};

    # ssl Settings.
    use constant SSL_ENABLE              => $config->{SSL_ENABLE};
    use constant SSL_CERTIFICATE_FILE    =>
      $config->{SSL_CERTIFICATE_FILE} || '';
    use constant SSL_CERTIFICATE_KEY_FILE =>
      $config->{SSL_CERTIFICATE_KEY_FILE} || '';
    use constant ALWAYS_USE_SSL          => $config->{ALWAYS_USE_SSL};
    use constant SSL_PORT                => $config->{SSL_PORT} || 443;

    # cookie Settings
    use constant AUTH_COOKIE             => 'BRICOLAGE_AUTH';
    use constant COOKIE                  => 'BRICOLAGE';
    use constant LOGIN_MARKER            => 'BRIC_LOGIN_MARKER';

    # DBI Settings.
    use constant DBD_TYPE                => 'Pg';
    use constant DBD_PACKAGE             => 'Bric::Util::DBD::' . DBD_TYPE;
    use constant DB_NAME                 => $config->{DB_NAME} || 'sharky';
    use constant DB_HOST                 => $config->{DB_HOST};
    use constant DB_PORT                 => $config->{DB_PORT};
    use constant DBI_USER                => $config->{DBI_USER} || 'castellan';
    use constant DBI_PASS                => $config->{DBI_PASS} || 'nalletsac';
    use constant DBI_CALL_TRACE          => $config->{DBI_CALL_TRACE} || 0;
    use constant DBI_PROFILE             => $config->{DBI_PROFILE} || 0;
    # DBI_CALL_TRACE and DBI_PROFILE imply DBI_DEBUG
    use constant DBI_DEBUG               => $config->{DBI_DEBUG}      ||
                                            $config->{DBI_CALL_TRACE} ||
                                            $config->{DBI_PROFILE}    || 0;

    # Distribution Settings.
    use constant ENABLE_DIST => $config->{ENABLE_DIST};
    use constant DIST_ATTEMPTS => $config->{DIST_ATTEMPTS} || 3;
    use constant PREVIEW_LOCAL => $config->{PREVIEW_LOCAL} ? qw(data preview) : 0;
    use constant PREVIEW_MASON => $config->{PREVIEW_MASON};
    use constant DEF_MEDIA_TYPE => $config->{DEF_MEDIA_TYPE} || 'text/html';
    use constant ENABLE_SFTP_MOVER => $config->{ENABLE_SFTP_MOVER};

    # Mason settings.
    use constant MASON_COMP_ROOT         => PREVIEW_LOCAL && PREVIEW_MASON ?
      [[bric_ui => $config->{MASON_COMP_ROOT}],
       [bric_preview => catdir($config->{MASON_COMP_ROOT}, PREVIEW_LOCAL)]]
        : [[bric_ui => $config->{MASON_COMP_ROOT}]];

    use constant MASON_DATA_ROOT         => $config->{MASON_DATA_ROOT}
      || catdir($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'data');
    use constant MASON_ARGS_METHOD       => 'mod_perl';  # Could also be 'CGI'

    # Burner settings.
    use constant BURN_ROOT               => $config->{BURN_ROOT}
      || catdir(MASON_DATA_ROOT, 'burn');
    use constant STAGE_ROOT              => catdir(BURN_ROOT, 'stage');
    use constant PREVIEW_ROOT            => catdir(BURN_ROOT, 'preview');
    use constant BURN_COMP_ROOT          => catdir(BURN_ROOT, 'comp');
    use constant BURN_DATA_ROOT          => catdir(BURN_ROOT, 'data');
    use constant BURN_ARGS_METHOD        => MASON_ARGS_METHOD;
    use constant TEMPLATE_BURN_PKG       => 'Bric::Util::Burner::Commands';
    use constant INCLUDE_XML_WRITER      => $config->{INCLUDE_XML_WRITER};
    use constant XML_WRITER_ARGS         => $config->{XML_WRITER_ARGS} ?
      (eval "$config->{XML_WRITER_ARGS}" ) : ();

    # System User (The user and group under which the server children run). use
    use constant SYS_USER => scalar getpwnam($config->{SYS_USER} or "nobody");
    use constant SYS_GROUP => scalar getgrnam($config->{SYS_GROUP} or "nobody");

    # Cookie/Session Settings.
    # AUTH_TTL is in seconds.
    use constant AUTH_TTL                => $config->{AUTH_TTL} || 8 * 60 * 60;
    use constant AUTH_SECRET             => $config->{AUTH_SECRET}
      || '^eFH;5D,~3!f9o&3f_=dwePL3f:/.Oi|FG/3sd9=45oi%8GF;*)4#0gn3)34tf\`3~'
         . 'fdIf^ N;:';

    # QA Mode settings.
    use constant QA_MODE                 => $config->{QA_MODE} || 0;
    use constant TEMPLATE_QA_MODE        => $config->{TEMPLATE_QA_MODE} || 0;

    # Character translation settings.
    use constant CHAR_SET                => $config->{CHAR_SET} || 'UTF-8';

    # Time constants.
    use constant ISO_8601_FORMAT         => "%Y-%m-%d %T";

    # Admin group ID. This will go away once permissions are implemented.
    use constant ADMIN_GRP_ID            => 6;

    # the base directory that will store media assets
    use constant MEDIA_URI_ROOT => '/data/media';
    use constant MEDIA_FILE_ROOT => catdir(MASON_COMP_ROOT->[0][1],
                                           'data', 'media');

    # The minimum login name and password lengths users can enter.
    use constant LOGIN_LENGTH            => $config->{LOGIN_LENGTH} || 6;
    use constant PASSWD_LENGTH           => $config->{PASSWD_LENGTH} || 6;

    # Error Page Setting.
    use constant ERROR_URI => (QA_MODE) ? '/errors/error.html' : '/errors/500.mc';

    # Email Settings.
    use constant SMTP_SERVER => $config->{SMTP_SERVER}
      || $config->{VHOST_SERVER_NAME};

    # Alert Settings.
    use constant ALERT_FROM => $config->{ALERT_FROM};
    use constant ALERT_TO_METH => lc $config->{ALERT_TO_METH} || 'bcc';

    # UI Settings.
    use constant FIELD_INDENT => 125;
    use constant DISABLE_NAV_LAYER => $config->{DISABLE_NAV_LAYER};

    # Search Settings
    use constant FULL_SEARCH => => $config->{FULL_SEARCH};

    # FTP Settings
    use constant ENABLE_FTP_SERVER => $config->{ENABLE_FTP_SERVER} || 0;
    use constant FTP_ADDRESS       => $config->{FTP_ADDRESS}       || "";
    use constant FTP_PORT          => $config->{FTP_PORT}          || 2121;
    use constant FTP_DEBUG         => $config->{FTP_DEBUG}         || 0;
    use constant FTP_LOG           => $config->{FTP_LOG}           ||
      catdir($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'ftp.log');

    # Output Channel Settings.
    use constant DEFAULT_FILENAME => => $config->{DEFAULT_FILENAME} || 'index';
    use constant DEFAULT_FILE_EXT => => $config->{DEFAULT_FILE_EXT} || 'html';

    # Temp Dir Setting
    use constant TEMP_DIR        => $config->{TEMP_DIR} || tmpdir();

    # Process Size Limit Settings
    use constant CHECK_PROCESS_SIZE     => $config->{CHECK_PROCESS_SIZE};
    use constant MAX_PROCESS_SIZE       => $config->{MAX_PROCESS_SIZE} || 56000;
    use constant CHECK_FREQUENCY        => $config->{CHECK_FREQUENCT} || 1;
    use constant MIN_SHARE_SIZE         => $config->{MIN_SHARE_SIZE} || 0;
    use constant MAX_UNSHARED_SIZE      => $config->{MAX_UNSHARED_SIZE} || 0;

    # Profiler settings
    use constant PROFILE => $config->{PROFILE} || 0;

    # Okay, now load the end-user's code, if any.
    if ($config->{PERL_LOADER}) {
        my $pkg = TEMPLATE_BURN_PKG;
        eval "package $pkg; $config->{PERL_LOADER}";
    }
}

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields

#--------------------------------------#
# Instance Fields

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

NONE

=over 4

=cut

#--------------------------------------#
# Constructors

#--------------------------------------#

=head2 Public Class Methods

NONE

=cut

#--------------------------------------#

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

=back

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb  E<lt>garth@perijove.comE<gt>

David Wheeler E<lt>david@wheeler.netE<gt>

=head1 SEE ALSO

L<Bric::Admin>

=cut
