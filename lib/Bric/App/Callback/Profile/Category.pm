package Bric::App::Callback::Profile::Category;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'category';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::Util::Grp;
use Bric::Util::Trans::FS;

my $type = 'category';
my $disp_name = get_disp_name($type);
my $pl_name = get_class_info($type)->get_plural_name;
my $class = get_package_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $cat = $self->obj;

    my $id = $param->{"${type}_id"};
    my $name = "&quot;$param->{name}&quot;";

    # This will fail if for some bad reason site_id has not yet been set on $cat
    my $root_id = Bric::Biz::Category->site_root_category_id($param->{site_id});

    if ($param->{delete} || $param->{delete_cascade}) {
        if ($id == $root_id) {
            # You can't deactivate the root category!
            add_msg($self->lang->maketext("$disp_name [_1] cannot be deleted.",
                                    $name));
            return $cat;
        }
        my ($arg, $msg, $key);
        if ($param->{delete_cascade}) {
            # We're going to delete all subcategories, too.
            $arg = { recurse => 1 };
            $msg = $self->lang->maketext("$disp_name profile [_1] and all its " .
                                   "$pl_name deleted.", $name);
            $key = '_deact_cascade';
        } else {
            # We'll just be deleting this category.
        $msg = $self->lang->maketext("$disp_name profile [_1] deleted.",$name);
            $key = '_deact';
        }
        # Deactivate it.
        $cat->deactivate($arg);
        $cat->save;
        log_event($type . $key, $cat);
        add_msg($msg);
    } else {
        # Roll in the changes.
        $cat->set_name($param->{name});
        $cat->set_description($param->{description});
        $cat->set_ad_string($param->{ad_string});
        $cat->set_ad_string2($param->{ad_string2});
        $cat->set_site_id($param->{site_id})
          if exists $param->{site_id};

        # if this is not ROOT, we have work to do
        if (((defined $id and $id != $root_id) or not defined $id)
            and defined $param->{parent_id}) {

            # get and set the parent
            my $par = $class->lookup({id => $param->{parent_id}});
            $par->add_child([$cat]);

            # make sure the directory name does not
            # already exist as a child of the parent
            if (exists $param->{directory}) {
                my $p_id = $par->get_id;

                if (defined($id) and $id == $p_id
                    or grep $_->get_id == $p_id, $cat->children) {
                    add_msg("Parent cannot choose itself or its child as"
                            . " its parent. Try a different parent.");
                    return $cat;
                }

                if (@{ $class->list({ directory => $param->{directory},
                                      site_id   => $cat->get_site_id,
                                      parent_id => $p_id}) }) {
                    my $uri = Bric::Util::Trans::FS->cat_uri
                      ($par->get_uri, $param->{directory});
                    add_msg($self->lang->maketext
                            ('URI [_1] is already in use. Please ' .
                             'try a different directory name or ' .
                             'parent category.', $uri ));
                    return $cat;
                }
                if ($param->{directory} =~ /[^\w.-]+/) {
                    add_msg($self->lang->maketext("Directory name [_1] contains "
                            . "invalid characters. Please try a different "
                            . "directory name.","'$param->{directory}'"));
                    return $cat;
                } else {
                    $cat->set_directory($param->{directory});
                }
            }
        }

        # Delete old keywords.
        my $old;
        foreach (@{ mk_aref($param->{del_keyword}) }) {
            next unless $_;
            my $kw = Bric::Biz::Keyword->lookup({ id => $_ }) || next;
            push @$old, $kw;
        }
        $cat->del_keywords(@$old) if $old;

        # Add new keywords.
        my $new;
        foreach (@{ mk_aref($param->{keyword}) }) {
            next unless $_;
            my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
            unless ($kw) {
                $kw = Bric::Biz::Keyword->new({ name => $_})->save;
                log_event('keyword_new', $kw);
            }
            push @$new, $kw;
        }
        $cat->add_keywords(@$new) if $new;

        log_event($type . (defined $param->{category_id} ? '_save' : '_new'),
                  $cat);

        # Save changes.
        $cat->save;

        # Take care of group managment.
        if ($param->{add_grp} or $param->{rem_grp}) {

            my @add_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
              @{mk_aref($param->{add_grp})};
            my @del_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
              @{mk_aref($param->{rem_grp})};

            foreach $cat ( $param->{grp_cascade}
                           ? Bric::Biz::Category->list
                             ({uri => $cat->get_uri . '%'})
                           : $cat
                          ) {

                # Assemble the new member information.
                foreach my $grp (@add_grps) {
                    # Add the user to the group.
                    $grp->add_members([{ obj => $cat }]);
                    $grp->save;
                    log_event('grp_save', $grp);
                }

                foreach my $grp (@del_grps) {
                    # Deactivate the user's group membership.
                    foreach my $mem ($grp->has_member({ obj => $cat })) {
                        $mem->deactivate;
                        $mem->save;
                    }

                    $grp->save;
                    log_event('grp_save', $grp);
                }
            }
        }

        add_msg("$disp_name profile $name saved.");
    }
    # Redirect back to the manager.

    set_redirect('/admin/manager/category');
    return $cat;
}


1;
