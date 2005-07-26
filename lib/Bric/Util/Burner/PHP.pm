package Bric::Util::Burner::PHP;
###############################################################################

=head1 NAME

Bric::Util::Burner::PHP - Bric::Util::Burner subclass to publish business assets using PHP templates.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2004-11-19 03:55:15 -0500 (Fri, 19 Nov 2004) $

=head1 SYNOPSIS

  use Bric::Util::Burner::PHP;

  # Create a new PHP burner using the settings from $burner
  my $php_burner = Bric::Util::Burner::PHP->new($burner);

 # Burn an asset, get back a list of resources
  my $resources = $php_burner->burn_one($ba, $at, $oc, $cat);

=head1 DESCRIPTION

This module handles burning business story resources (files) PHP tempmlates.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Fault qw(throw_gen throw_burn_error isa_bric_exception);
use Bric::Util::Trans::FS;
use Bric::Config qw(:burn :l10n);
use PHP::Interpreter;

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric::Util::Burner);

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#


#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields({
        #- Per burn/deploy values.
        job            => Bric::FIELD_READ,
        more_pages     => Bric::FIELD_READ,

        # Private Fields
        _php            => Bric::FIELD_NONE,
        _comp_root      => Bric::FIELD_NONE,
        _buf            => Bric::FIELD_NONE,
        _writee         => Bric::FIELD_NONE,
        _elem           => Bric::FIELD_NONE,
        _at             => Bric::FIELD_NONE,
        _files          => Bric::FIELD_NONE,
        _page_place     => Bric::FIELD_NONE,
    });
}

__PACKAGE__->_register_burner(
    Bric::Biz::AssetType::BURNER_PHP,
    category_fn    => 'category',
    cat_fn_has_ext => 0,
    exts           => {
        php => 'PHP (.php)',
    }
);


#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $obj = Bric::Util::Burner::PHP->new($burner);

Creates a new PHP burner object.  Takes a single parameters -
$burner - which is a Bric::Util::Burner object.  The new object will
has its attributes initialized by the passed object.

=cut

sub new {
    my ($class, $burner) = @_;
    my $init = { %$burner };

    # create the object using Bric's constructor and return it
    return $class->Bric::new($init);
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=cut

#------------------------------------------------------------------------------#

=item $resources = $b->burn_one($ba, $at, $oc, $cat);

Publishes an asset.  Returns a list of resources burned.  Parameters are:

=over 4

=item *

$ba

A business asset object to publish.

=item *

$at

A asset type object for $ba

=item *

$oc

An output channel object to use for the publish

=item *

cat

A category in which to publish.

=back

=cut

sub burn_one {
    my ($self, $story, $oc, $cat, $at) = @_;
    my $element = $story->get_tile();

    # Determine the component roots.
    my $comp_dir = $self->get_comp_dir;
    my $template_roots;
    foreach my $inc ($oc, $oc->get_includes) {
        my $inc_dir = "oc_" . $inc->get_id;

        push @$template_roots, $fs->cat_dir($self->get_sandbox_dir, $inc_dir)
          if $self->get_sandbox_dir;

        push @$template_roots, $fs->cat_dir($comp_dir, $inc_dir);
    }

    # Instantiate the PHP interpreter.
    my $php = PHP::Interpreter->new({
        # XXX Questionable layout things, but we got the time to sort it out
        OUTPUT       => \my $outbuf,
        INCLUDE_PATH => join(':', @$template_roots),
        BRIC         => {
            burner  => $self,
            story   => $story,
            element => $element,
        },
    });
    $php->eval(q/function setBric($key, $var) {
        global $BRIC;
        $BRIC[$key] = $var;
    }/);

    # Find the story type element template.
    my $template;
    my @cats = map { $_->get_directory } $self->get_cat->ancestry;
    {
        my @cats = map { $_->get_directory } $self->get_cat->ancestry;
        my $tmpl_name = $element->get_key_name . '.php';
        do {
            foreach my $troot (@$template_roots) {
                my $path = $fs->cat_dir($troot, @cats, $tmpl_name);
                if(-e $path) {
                    $template = $path;
                    goto LABEL;
                }
            }
        } while(pop @cats);
      LABEL:
    }

    my @cat_tmpls;
    {
        # search up category hierarchy for category templates.
        my @cats = map { $_->get_directory } $self->get_cat->ancestry;

        do {
            # if the file exists, return it
            for my $troot (@$template_roots) {
                my $path = $fs->cat_dir($troot, @cats, 'category');
                next unless -e $path;
                unshift @cat_tmpls, $path;
                last;
            }
        } while (pop @cats);
    }

    $self->_set([qw(_buf      page story   element   _comp_root       _php)],
                [   \$outbuf, 0,   $story, $element, $template_roots, $php]);
    $self->_push_element($element);

    while (1) {
        use utf8;
        no warnings;
        eval { $php->include($template) };
        if (my $err = $@) {
            $err->rethrow if isa_bric_exception $err;
            throw_burn_error
                error   => "Error executing '$template'",
                payload => $@,
                mode    => $self->get_mode,
                oc      => $self->get_oc->get_name,
                cat     => $self->get_cat->get_uri,
                elem    => $element->get_name
              if $@;
        }

        # Execute category templates.
        for my $cat_tmpl (@cat_tmpls) {
            $php->setBric(CONTENT => $outbuf);
            $outbuf = '';
            eval { $php->include($cat_tmpl) };
            throw_burn_error
                error   => "Error executing '$cat_tmpl'",
                payload => $@,
                mode    => $self->get_mode,
                oc      => $self->get_oc->get_name,
                cat     => $self->get_cat->get_uri
              if $@;
        }
        $php->setBric(CONTENT => '');

        my $page = $self->_get('page') + 1;

        if ($outbuf !~ /^\s*$/) {
            my $file = $self->page_filepath($page);
            my $uri  = $self->page_uri($page);

            # Save the page we've created so far.
            open(OUT, ">$file")
              or throw_gen error => "Unable to open '$file' for writing",
                           payload => $!;
            binmode(OUT, ':' . $self->get_encoding || 'utf8') if ENCODE_OK;
            print OUT $outbuf;
            close(OUT);
            $outbuf = '';
            # Add a resource to the job object.
            $self->add_resource($file, $uri);
        }

        $self->_set(['page'] => [$page]);
        last unless $self->_get('more_pages');
    }

    $self->_pop_element;

    $self->_set([qw(_php _comp_root page)] => [undef, undef, 0]);
    return $self->get_resources;
}

################################################################################

=item my $bool = $burner->chk_syntax($ba, \$err)

Compiles the template found in $ba. If the compile succeeds with no errors,
chk_syntax() returns true. Otherwise, it returns false, and the error will be
in the $err variable passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method has not yet been implemented for PHP templates. For the
time being, it always returns success.

=cut

sub chk_syntax {
    my ($self, $ba, $err_ref) = @_;
    # Just succeed if there is no template source code.
    my $data = $ba->get_data or return $self;
    #no way to do this yet
    return $self;
    die;
}

#------------------------------------------------------------------------------#

=item my $template = $burner->find_template($uri, $tmpl_name)

Finds the first instance of the template with the name $tmpl_name in the URI
directory hierarchy in $uri. Returns the template path, if it exists, and undef
if it does not. For example:

  my $uri = '/foo/bar/bletch';
  my $tmpl_name = 'story.mc';
  my $template = $burner->find_template($uri, $tmpl_name);

The find_template() method will look first for '/foo/bar/bletch/story.mc', and
return that string if the template exists. If it doesn't, it'll look for
'/foo/bar/story.mc'. If it doesn't find that, it'll look for '/foo/story.mc' and
then '/story.mc'. If it finds none of these, it will rutrn null (or an empty
list in an array context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses HTML::Mason::Interp->comp_exists() internally to determine if the
template exists.

=cut

sub find_template {
    my ($self, $uri, $name) = @_;
    my @cats = $fs->split_uri($uri);
    my $root = $self->_get('_comp_root');
    do {
	# if the file exists, return it
	foreach my $troot (@$root) {
	    my $path = $fs->cat_dir($troot, @cats, $name);
	    return $path if -e $path;
	}
    } while(pop(@cats));
    return;
}

#------------------------------------------------------------------------------#

=item my $template = $burner->find_first_template(@tmpl_list)

Returns the path to the first template it finds in @tmpl_list. It uses
find_template() (see above) to examine each template in @tmpl_list in turn.
Thus, this method looks down the directory hierarchy of each template in
@tmpl_list before moving on to the next one. For example:

  my @tmpl_list = ('/foo/bar/story.mc', '/sci/anthro/fizzle.mc');
  my $template =  $burner->find_first_template(@tmpl_list)

In this example, find_first_template will return the name of the first template
it finds in this order:

=over 4

=item *

/foo/bar/story.mc'

=item *

/foo/story.mc'

=item *

/story.mc'

=item *

/sci/anthro/fizzle.mc'

=item *

/sci/fizzle.mc'

=item *

/fizzle.mc'

=back

If no template is found to exist, find_first_template will return undef (or an
empty list in an array context).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> See also find_template() above.

=cut

sub find_first_template {
    my $self = shift;
    while (my $tmpl = shift) {
        $tmpl = $self->find_template($fs->uri_dir_name($tmpl),
                                     $fs->uri_base_name($tmpl))
          || next;
        return $tmpl;
    }
    return;
}

#------------------------------------------------------------------------------#

=item $success = $b->display_pages($paginated_element_name)

=item $success = $b->display_pages($paginated_element_name, %ARGS)

=item $success = $b->display_pages(\@paginated_element_names, %ARGS)

A method to be called from template space. Use this method to display
paginated elements. If this method is used, the burn system will run once for
every page element listed in C<\@paginated_element_names> (or just
C<$paginated_element_name>) in the story; this is so that autohandlers will be
called when appropriate. All arguments after the first argument will be passed
to the template executed as its C<%ARGS> hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_pages {
    my $self = shift;
    my $names = shift;
    $names = [$names] unless ref $names;

    # Get the current element
    my $elem = $self->_current_element;
    my $page_place = $self->_get('_page_place') || 0;

    my ($next_page, $page_elem);
    my $tiles = $elem->get_tiles;
    foreach my $place ($page_place..$#$tiles) {
        my $e = $tiles->[$place];
        next unless $e->is_container;
        foreach my $name (@$names) {
            next unless $e->has_name($name);
            $page_elem ? $next_page = 1 : $page_elem = $e;
            next unless $next_page;
            last;
        }
    }

    # Set the 'more_pages' and '_page_place' properties.
    $self->_set([ qw(more_pages _page_place) ],
                [ $next_page,
                  $page_elem ? $page_elem->get_place + 1 : $page_place + 1 ]);

    $self->display_element($page_elem, @_);
}

#------------------------------------------------------------------------------#

=item $success = $b->display_element($element)

=item $success = $b->display_element($element, %ARGS)

A method to be called from template space. This method will find the mason
element associated with the element passed in and call C<< $m->comp >>. All
arguments after the first argument will be passed to the template executed as
its C<%ARGS> hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_element {
    my $self = shift;
    my $elem = shift or return;
    return $self->_display_container($elem) if $elem->is_container;
    my $buf = $self->_get('_buf');
    $$buf .= $elem->get_data;
    return $self;
}

##############################################################################

=item $output = $b->sdisplay_element($element)

A method to be called from template space. This is a C<sprint>-likef version
of C<display_element()>, i.e. it returns the output as a string rather than
outputting it it as C<display_element()> does.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub sdisplay_element {
    my $self = shift;
    my $elem = shift or return '';
    return $elem->get_data unless $elem->is_container;
    my ($php, $buf) = $self->_get(qw(_php _buf));
    $php->setOutputHandler(\my $ret);
    $self->_display_container($elem);
    $php->setOutputHandler($buf);
    return $ret;
}

##############################################################################

=item my $more_pages = $b->get_more_pages

  % unless ($burner->get_more_pages) {
        <h3>Last page</h3>
  % }

Returns true if more pages remain to be burned, and false if not. Only
enumerated when C<display_pages()> is being used to output pages.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

#==============================================================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

=item $template = $b->_load_template_element($element);

Given an element (a business asset/data tile) return the template element that
formats it.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _load_template_element {
    my ($self, $element) = @_;
    my ($oc, $cat) = $self->_get(qw(oc cat));

    # Get the path (based at comp_root) and the template name.
    my $tmpl_path = $cat->ancestry_path;
    my $tmpl_name = $element->get_key_name . '.php';
    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->find_template($tmpl_path, $tmpl_name)
      or throw_burn_error error => "Unable to find template '$tmpl_name'",
                          mode  => $self->get_mode,
                          oc    => $self->get_oc->get_name,
                          cat   => $self->get_cat->get_uri,
                          elem  => $element->get_name;
    return $tmpl;
}

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element

Return the current element in this context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _current_element { $_[0]->_get('_elem')->[-1] }

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element_type

Return the current element type in this context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _current_element_type { $_[0]->_get('_at')->[-1] }

#------------------------------------------------------------------------------#

=item $b = $b->_push_element($element)

=item $element = $b->_pop_element;

Push and pops an element from the element stack. As a story is burned, the burn
process can travel down several elements deep. This stack records the order in
which each element was transversed so when the burn process exits an element,
the correct and current element is at the top of the stack.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _push_element {
    my ($self, $element) = @_;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    push @$elem_stack, $element;
    push @$at_stack, $element->get_element;

    $self->_set(['_elem', '_at'], [$elem_stack, $at_stack]);
}

sub _pop_element {
    my $self = shift;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    pop @$at_stack;
    return pop @$elem_stack;
}

##############################################################################

=item $burner->_display_container($element)

Called by C<display_element()> and C<sidsplay_element()> this method uses the
PHP::Interpreter object to execute the element template for a container
element.

=cut

sub _display_container {
    my ($self, $elem) = @_;
    my $parent = $self->_current_element;
    $self->_push_element($elem);
    my $template = $self->_load_template_element($elem);
    my $php = $self->_get('_php');
    $php->setBric(element => $elem);
    eval { $php->include($template) };
    throw_burn_error
        error   => "Error executing '$template'",
        payload => $@,
        mode    => $self->get_mode,
        oc      => $self->get_oc->get_name,
        cat     => $self->get_cat->get_uri,
        elem    => $elem->get_name
      if $@;

    $self->_pop_element;
    $php->setBric(element => $parent);
    return $self;
}


=back

=head2 Private Functions

None.

=cut

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

Garth Webb L<gt>garth@perijove.comL<lt>

Sam Tregar L<gt>stregar@about-inc.comL<lt>

David Wheeler L<gt>david@wheeler.netL<lt>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner>

=cut
