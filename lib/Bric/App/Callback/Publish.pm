package Bric::App::Callback::Publish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'publish';

use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:aref :msg :history :browser redirect_onload);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Config qw(:prev);
use Bric::Util::Burner;
use Bric::Util::Job::Pub;
use Bric::App::Event qw(log_event);

sub preview : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};
    my $oc_id    = $param->{'oc_id'};

    # Note that we're previewing so that the error page will work correctly.
    if (my $ar = $self->apache_req) {
        $ar->notes("burner.preview" => 1);
    }

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => PREVIEW_ROOT,
                                      user_id => get_user_id });
    if (defined $media_id) {
        my $media = get_state_data('media_prof', 'media');
        unless ($media && (defined $media_id) && ($media->get_id == $media_id)) {
            $media = Bric::Biz::Asset::Business::Media->lookup
              ({ id => $media_id,
                 checkout => $param->{checkout} });
        }

        # Move out the story and then redirect to preview.
        if (my $url = $b->preview($media, 'media', get_user_id(), $oc_id)) {
            status_msg("Redirecting to preview.");
            # redirect_onload() prevents any other callbacks from executing.
            redirect_onload($url, $self);
        }
    } else {
        my $s = get_state_data('story_prof', 'story');
        unless ($s && defined $story_id && $s->get_id == $story_id) {
            $s = Bric::Biz::Asset::Business::Story->lookup
              ({ id => $story_id,
                 checkout => $param->{checkout} });
        }

        # Get all the related media to be previewed as well
        foreach my $ra ($s->get_related_objects) {
            next if ref $ra eq 'Bric::Biz::Asset::Business::Story';
            next unless $ra->is_active;

            unless ($ra->get_path) {
                status_msg('No file associated with media "[_1]". Skipping.',
                           $ra->get_title);
                next;
            }

            $b->preview($ra, 'media', get_user_id(), $oc_id);
        }
        # Move out the story and then redirect to preview.
        if (my $url = $b->preview($s, 'story', get_user_id(), $oc_id)) {
            status_msg("Redirecting to preview.");
            # redirect_onload() prevents any other callbacks from executing.
            redirect_onload($url, $self);
        }
    }
}

# this is used by Desk.pm to let the user deselect related assets
# published from the publish desk
sub select_publish : Callback(priority => 1) {  # run this before 'publish'
    my $self = shift;
    # (this was set in comp/widgets/publish/publish.mc)
    my $values = mk_aref($self->value);

    my (@story, @media);
    foreach my $val (@$values) {
        # Push on the related assets that were checked
        if ($val =~ s/^story=(\d+)$//) {
            push @story, $1;
        } elsif ($val =~ s/^media=(\d+)$//) {
            push @media, $1;
        }
    }

    set_state_data($self->class_key, story => \@story);
    set_state_data($self->class_key, media => \@media);
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    my $stories = mk_aref($story_pub_ids);
    my $media = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    my $count = @$stories;
    foreach my $sid (@$stories) {
        # Schedule
        my $s = Bric::Biz::Asset::Business::Story->lookup({id => $sid});
        my $name = 'Publish "' . $s->get_name . '"';
        my $job = Bric::Util::Job::Pub->new({
            sched_time    => $param->{pub_date},
            user_id       => get_user_id(),
            name          => $name,
            story_id      => $sid,
            priority      => $s->get_priority(),
        });
        $job->save();
        # Report publishing if the job was executed on save, otherwise
        # report scheduling
        my $saved = $job->get_comp_time() ? 'published' : 'scheduled for publication';
        add_msg(qq{Story "[_1]" $saved.},  $s->get_title)
           if $count <= 3;
        # Remove it from the desk it's on.
        if (my $d = $s->get_current_desk) {
            $d->remove_asset($s);
            $d->save;
        }

        # Remove it from the workflow by setting its workflow ID to undef
        if ($s->get_workflow_id
            && !$s->get_user__id # Not checked out.
            && $s->get_version == $s->get_current_version # Is the current version.
        ) {
            $s->set_workflow_id(undef);
            log_event("story_rem_workflow", $s);
        }
        $s->save();
    }

    $count = @$media;
    foreach my $mid (@$media) {
        # Schedule
        my $m = Bric::Biz::Asset::Business::Media->lookup({id => $mid});
        my $name = 'Publish "' . $m->get_name . '"';
        my $job = Bric::Util::Job::Pub->new({
            sched_time    => $param->{pub_date},
            user_id       => get_user_id(),
            name          => $name,
            media_id      => $mid,
            priority      => $m->get_priority,
        });
        $job->save();
        # Report publishing if the job was executed on save, otherwise
        # report scheduling
        my $saved = $job->get_comp_time() ? 'published' : 'scheduled for publication';
        add_msg(qq{Media "[_1]" $saved.}, $m->get_title)
          if $count <= 3;
        # Remove it from the desk it's on.
        if (my $d = $m->get_current_desk) {
            $d->remove_asset($m);
            $d->save;
        }
        # Remove it from the workflow by setting its workflow ID to undef
        if ($m->get_workflow_id) {
            $m->set_workflow_id(undef);
            log_event("media_rem_workflow", $m);
        }
        $m->save();
    }

    unless (exists($param->{'instant'}) && $param->{'instant'}) {
        # redirect_onload() prevents any other callbacks from executing.
        redirect_onload(last_page(), $self);
    }
}


1;
