package Bric::App::Callback::Profile::AlertType;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'alert_type';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);

my ($save);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $at = $self->obj;

    my $name = $param->{name} ? "&quot;$param->{name}&quot;" : '';
    if ($param->{delete}) {
	# Remove it.
	$at->remove;
	$at->save;
	log_event("${type}_del", $at);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted.", $name));
	set_redirect('/admin/manager/alert_type');
    } else {
	# Just save it.
	my $ret = &$save($param, $at, $name, $self);
        if ($ret) {
            $param->{'obj'} = $ret;
            return;
        }
        add_msg($self->lang->maketext("[_1] profile [_2] saved.", $disp_name, $name));
	set_redirect('/admin/manager/alert_type');
    }
}

sub recip : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $at = $self->obj;

    # Save it and let them edit recipients.
    my $name = $param->{name} ? "&quot;$param->{name}&quot;" : '';
    my $ret = &$save($param, $at, $name, $self);
    if ($ret) {
        $param->{'obj'} = $ret;
        return;
    }
    set_state_name('alert_type', $self->value);
    set_redirect("/admin/profile/$type/recip/$param->{alert_type_id}");
}

sub edit_recip : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $at = $self->obj;

    $at->add_users( $param->{ctype}, @{ mk_aref($param->{add_users}) } );
    $at->del_users( $param->{ctype}, @{ mk_aref($param->{del_users}) } );
    $at->add_groups( $param->{ctype}, @{ mk_aref($param->{add_groups}) } );
    $at->del_groups( $param->{ctype}, @{ mk_aref($param->{del_groups}) } );
    $at->save;
    add_msg($self->lang->maketext("[_1] recipients changed.",$param->{ctype}));
    set_redirect("/admin/profile/alert_type/$param->{alert_type_id}");
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;
    my $at = $self->obj;

    foreach my $id (@{ mk_aref($self->value) }) {
        my $at = $class->lookup({'id' => $id}) || next;
        if (chk_authz($at, EDIT, 1)) {
            $at->remove();
            $at->save();
            log_event($self->class_key . '_del', $at);
        } else {
            add_msg('Permission to delete "[_1]: denied.', $at->get_name);
        }
    }
}


###

$save = sub {
    my ($param, $at, $name, $self) = @_;
    # Roll in the changes.
    $at->set_name($param->{name});
    $at->set_owner_id($param->{owner_id});
    if (defined $param->{alert_type_id}) {
	# Set the subject and the message.
        $at->set_subject($param->{subject});
	$at->set_message($param->{message});

	# Set the active flag.
	my $act = $at->is_active;
	if (exists $param->{active} && !$act) {
	    # They want to activate it. Do so.
	    $at->activate;
	    log_event("${type}_act", $at);
	} elsif ($act && !exists $param->{active}) {
	    # Deactivate it.
	    $at->deactivate;
	    log_event("${type}_deact", $at);
	}

	# Update the rules.
	my $rids = mk_aref($param->{alert_type_rule_id});
	for (my $i = 0; $i < @{$param->{attr}}; $i++) {
	    if (my $id = $rids->[$i]) {
		my ($r) = $at->get_rules($id);
		$r->set_attr($param->{attr}[$i]);
		$r->set_operator($param->{operator}[$i]);
		$r->set_value($param->{value}[$i]);
	    } else {
		next unless $param->{attr}[$i];
		my $r = $at->new_rule($param->{attr}[$i], $param->{operator}[$i],
				      $param->{value}[$i]);
	    }
	}
	$at->del_rules(@{ mk_aref($param->{del_alert_type_rule})} )
	  if $param->{del_alert_type_rule};
    } else {
	if (defined $param->{event_type_id}) {
	    $at->set_event_type_id($param->{event_type_id});
	    if ($at->name_used) {
                add_msg($self->lang->maketext("The name [_1] is already used by another [_2].",$name,$disp_name));
	    } else {
		$at->save;
		log_event($type . '_new', $at);
	    }
	}
	return $at;
    }

    # Make sure the name isn't already in use.
    if ($at->name_used) {
        add_msg($self->lang->maketext("The name [_1] is already used by another [_2].",$name,$disp_name));
	return $at;
    }

    $at->save;
    log_event($type . (defined $param->{alert_type_id} ? '_save' : '_new'),
	      $at);
    return;
};


1;
