package Bric::App::Callback::Workspace;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'workspace';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref :msg);
use Bric::App::Session qw(:user);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Util::Burner;

my $pkgs = {
    story => 'Bric::Biz::Asset::Business::Story',
    media => 'Bric::Biz::Asset::Business::Media',
    formatting => 'Bric::Biz::Asset::Formatting',
};
my $keys = [ keys %$pkgs ];
my $dskpkg = 'Bric::Biz::Workflow::Parts::Desk';


sub checkin : Callback {
    my $self = shift;

    # Checking in assets and moving them to another desk.
    my %desks;
    foreach my $next (@{ mk_aref($self->params->{"desk_asset|next_desk"})}) {
        next unless $next;
        my ($aid, $from_id, $to_id, $key) = split /-/, $next;
        my $a = $pkgs->{$key}->lookup({ id => $aid, checkout => 1 });
        my $curr = $desks{$from_id} ||= $dskpkg->lookup({ id => $from_id });
        my $next = $desks{$to_id} ||= $dskpkg->lookup({ id => $to_id });
        $curr->checkin($a);
        log_event("${key}_checkin", $a, { Version => $a->get_version });

        if ($curr->get_id != $next->get_id) {
            $curr->transfer({ to    => $next,
                              asset => $a });
            log_event("${key}_moved", $a, { Desk => $next->get_name });
        }
        $curr->save;
        $next->save;
    }
}

sub delete : Callback {
    my $self = shift;
    my $burn = Bric::Util::Burner->new;

    # Deleting assets.
    foreach my $key (@$keys) {
        foreach my $aid (@{ mk_aref($self->params->{"${key}_delete_ids"}) }) {
            my $a = $pkgs->{$key}->lookup({ id => $aid, checkout => 1 });
            if (chk_authz($a, EDIT, 1)) {
                my $d = $a->get_current_desk;
                $d->checkin($a);
                $d->remove_asset($a);
                $d->save;
                log_event("${key}_rem_workflow", $a);
                $a->set_workflow_id(undef);
                $a->deactivate;
                $a->save;

                if($key eq 'formatting') {
                    $burn->undeploy($a);
                    my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
                    $sb->undeploy($a);
                }
                log_event("${key}_deact", $a);
            } else {
                add_msg('Permission to delete "[_1]" denied.', $a->get_name);
            }
        }
    }
}


1;
