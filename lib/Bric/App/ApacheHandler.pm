package Bric::App::ApacheHandler;

=head1 NAME

Bric::App::ApacheHandler - subclass of HTML::Mason::ApacheHandler

=head1 VERSION

$Revision: 1.5 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.5 $ )[-1];

=head1 DATE

$Date: 2003-09-15 20:45:35 $

=head1 DESCRIPTION

This package is a subclass of HTML::Mason::ApacheHandler. It replaces
the functionality previously provided by Bric::App::Handler::load_args;
that is, it does some processing of the GET and POST data.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::App::Callback;
use Bric::Util::Fault qw(:all);

################################################################################
# Inheritance
################################################################################
use base qw(HTML::Mason::ApacheHandler);

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

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

Inherited.

=head1 PRIVATE

None.

=cut

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

Scott Lanning <slanning@theworld.com>

=head1 SEE ALSO

L<Bric::App::Handler>, L<HTML::Mason::ApacheHander>

=cut
