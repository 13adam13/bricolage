<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.9 $

=head1 DATE

$Date: 2003-02-12 15:53:33 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/displayFormElement.mc",
        vals => $vals,
        key => 'color'
        js => 'optional script'
);
$m->comp("/widgets/profile/displayFormElement.mc",
        key => "fname",
        objref => $obj,
        js => 'optional script'
);
=head1 DESCRIPTION

There are two usages:

=over 4

=item 1)

Pass a vals hash with values with which to populate the element, and properties
of the form element, display form element html. For example:

  my $vals = {
               disp      => "Pick color",
               value     => 'Red', # optional, if you want one preselected
               props     => { 
                              type => 'select',
                              vals => {
                                        1 => 'Red',
                                        2 => 'Blue',
                                        3 => 'Orange'
                                      }
                            }
             };

  $m->comp("/widgets/profile/displayFormElement.mc", 
	   vals => $vals,
           key  => 'color',
	   js   => 'optional javascript string'
	  );

=item 2)

Pass an object and field name. The element will introspect the object and
populate the form field with whatever it finds there. For example:

  $m->comp("/widgets/profile/displayFormElement.mc", 
	   key    => "fname",
           objref => $obj,
	   js     => 'optional javascript string'
	  );

=back

All possible attributes of a form field are supported, but all have defaults.
If you choose to override the default javascript, none of the default behavior
(ie, setting the changed flag) will be implemented, unless the overriding 
string does so explicitly.  This is a feature, as it allows the onChange
to be eliminated entirely if needed.

The types of form fields supported are:

=over 4

=item *

text

=item *

password

=item *

select

=item *

hidden

=item *

textarea

=item *

checkbox

=item *

radio

=item *

single_rad - A single radio input, rather than an array of them.

=item *

date - Simple date formatting.

=back

=cut

</%doc>
<%args>

$vals     => 0
$name     => undef
$key      => ''
$objref   => 0
$js       => ''
$useTable => 1
$readOnly => 0
$width    => undef
$indent   => undef
$cols     => undef
$rows     => undef
</%args>
<%perl>;
my $agent = $m->comp("/widgets/util/detectAgent.mc");
$vals->{props}{cols} = $cols if ($cols);
$vals->{props}{rows} = $rows if ($rows);

if ($objref) {
    # fetch ref to introspection hash
    my $methods = $objref->my_meths;
    # basically, switch on this value to determine form element type.
    my $formType = $methods->{$key}{props}{type} || return;
    # Determine if we're fetching a date, and if so, get it in the right format.
    my @date_arg = $formType eq 'date' ? (ISO_8601_FORMAT) : ();
    # Fetch the value.
    my $value = $methods->{$key}{get_meth}->($objref, @date_arg,
      @{ $methods->{$key}{get_args} }) if $methods->{$key}{get_meth};
    $width  ||= 578;
    $indent ||= FIELD_INDENT;
    my $label    =  ($methods->{$key}{req}) ? "redLabel" : "label";

    # Get the name, if necessary.
    $name = $methods->{$key}{disp} unless defined $name;

    # Assemble javascript.
    if (! $methods->{$key}{set_meth} ) {
	# Don't overwrite another onFocus method.
	$js .= ' onFocus="blur();"' unless index($js, 'onFocus') != -1;
    }

    # Execute the formatting code.
    $formSubs{$formType}->($key, $methods->{$key}, $value, $js, $name, $width,
                           $indent, $useTable, $label, $readOnly, $agent) if $formSubs{$formType};

    $m->out(qq{\n<script language="javascript">requiredFields['$key'] = }
	    . qq{"$methods->{$key}{disp}"</script>\n}) if $methods->{$key}{req};
} elsif ($vals) {
    my $value     = $vals->{value};
    my $formType  = $vals->{props}{type} || return;;
    $width   ||= $vals->{width}  ? $vals->{width}  : 578;
    $indent  ||= $vals->{indent} ? $vals->{indent} : FIELD_INDENT;
    my $label     =  ($vals->{req}) ? "redLabel" : "label";

    # Get the name, if necessary.
    $name = $vals->{disp} unless defined $name;
    $js = $vals->{js} || $js || '';

    # Execute the formatting code.
    $formSubs{$formType}->($key, $vals, $value, $js, $name, $width, $indent,
                           $useTable, $label, $readOnly, $agent) if $formSubs{$formType};

    $m->out(qq{\n<script language="javascript">requiredFields['$key'] = }
	    . qq{"$vals->{disp}";\n</script>\n}) if $vals->{req};
} else {
    # Fuhgedaboudit!
}

return $key;

</%perl>
<%once>;
my $opt_sub = sub {
    my ($k, $v, $value) = @_;
    for ($k, $v, $value) { $_ = '' unless defined $_ }
    $v = escape_html($v) if $v;
    my $out = qq{<option value="$k"};
    # select it if there's a match
    $out .= " selected" if (ref $value && $value->{$k}) || $k eq $value;
    return "$out>". $lang->maketext( $v ) . "</option>\n";
};

my $rem_sub = sub {
    my ($width, $indent) = @_;
    my $remainder = $width - $indent;
    $remainder = $remainder < 0 ? 0 : $remainder;
    return qq{</td><td width="$remainder">};
};

my $len_sub = sub {
    my ($vals) = @_;
    my $max = $vals->{props}{maxlength} || 128;
    my $len = $vals->{props}{length} || 32;
    return qq{ maxlength="$max" size="$len"};
};

my $inpt_sub = sub {

    my ($type, $key, $vals, $value, $js, $name, $width, $indent,
        $useTable, $label, $readOnly, $agent, $extra) = @_;
    my $class = ($type eq "text" || $type eq "password")
      ? qq{ class="textInput"} : "";
    $extra ||= '';
    my $out;
    my $disp_value = defined $value && $type ne 'password' ? ' value="'
      . escape_html($value) . '"' : '';
    $key = escape_html($key) if $key;
    $js = $js ? " $js" : '';

    if ($type ne "checkbox" && $type ne "hidden") {
	$out = $useTable ?  qq{<table border="0" width="$width"><tr><td align="right"}
	  . qq{ width="$indent">} : '';
        $out .= $name ? qq{<span class="$label">}.$lang->maketext($name).':</span>'
	  : ($useTable) ? '&nbsp;':'';
	$out .= &$rem_sub($width, $indent) if $useTable;

	if (!$readOnly) {
	    $out .= qq{<input type="$type"$class} . qq{ name="$key"$disp_value$extra$js />};
	} else {
	    $out .= ($type ne "password") ? " $value" : "********";
	}

    } else {

	$out = $useTable ?  qq{<table border="0" width="$width"><tr><td align="right"}
	  . qq{ width="$indent">} : '';
	$out .= qq{<span class="$label">}.$lang->maketext($name).':</span>'
	  if $name && !$vals->{props}{label_after};
	$out .= &$rem_sub($width, $indent) if $useTable;

	if (!$readOnly) {
	    $out .= qq{<input type="$type" name="$key"$disp_value$extra$js />};
	} else {
	    if ($type eq "radio" || $type eq "checkbox") {
		$out .= " ". $lang->maketext( ($value) ? "Yes" : "No" );
		$out .= "<br />";
	    }
	}

	$out .= qq{ <span class="label">} . $lang->maketext($name) . '</span>&nbsp;'
	  if $name && $vals->{props}{label_after};
    }

    $out .= $useTable ? "</td></tr></table>" : '';

    $m->out($out);
};

my %formSubs = (
	text => sub { &$inpt_sub('text', @_, &$len_sub($_[1]) ) },
        password => sub { &$inpt_sub('password', @_, &$len_sub($_[1]) ) },
        hidden => sub { &$inpt_sub('hidden', @_) },

        date => sub {
	    my ($key, $vals, $value, $js, $name,$width, $indent, $useTable,
		$label, $readOnly, $agent) = @_;
            $m->comp("/widgets/select_time/select_time.mc",
		     base_name => $key,
		     def_date  => $value,
		     useTable  => $useTable,
		     width     => $width,
		     disp      => $name
		    );
        },

	checkbox => sub {
	    my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
		$label, $readOnly, $agent) = @_;
            $name = $lang->maketext($name);
	    my $extra = '';
	    if (exists $vals->{props}{chk}) {
		$extra .= ' checked' if $vals->{props}{chk}
	    } elsif ($value) {
		$extra .= ' checked';
	    }
	    $indent -= 5 if ($useTable && !$readOnly);
	    &$inpt_sub('checkbox', $key, $vals, $value, $js, $name, $width,
		       $indent, $useTable, $label, $readOnly, $agent, $extra);
	},

	textarea => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
		$label, $readOnly, $agent) = @_;
            $name = $lang->maketext($name);
	    my $rows =  $vals->{props}{rows} || 5;
	    my $cols = $vals->{props}{cols}  || 30;

	    # adjust defaults by platform/browser
	    # ns displays big boxes, usually
	    $cols = ($agent->{browser} eq "Netscape" && $agent->{os} ne "MacOS")
	      ? $cols *.8 : $cols;

	    my $out;
	    $out .= qq{<table border="0" width="$width"><tr><td align="right"}
	      . qq{ width="$indent" valign="top">} if $useTable;
	    $out .= $name ? qq{<span class="$label">$name:</span><br />\n} : '';
	    $out .= &$rem_sub($width, $indent) if $useTable;
	    $value = $value ? escape_html($value) : '';
	    $key = $key ? escape_html($key) : '';

	    if (!$readOnly) {
		$js = $js ? " $js" : '';
		$out .= qq{<textarea name="$key" rows="$rows" cols="$cols" width="200"}
		  . qq{ wrap="soft" class="textArea"$js>$value</textarea><br />\n};
	    } else {
		$out .= $value;
	    }
	    $out .= "\n</td></tr></table>\n" if $useTable;
	    $m->out($out);
	},

	select => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
		$label, $readOnly, $agent) = @_;
	    my $out='';

	    $indent -= 7 if ($agent->{browser} eq "Netscape");
#	    $width += 4 if (!$readOnly && $agent->{browser} eq "Netscape");
	    if ($useTable) {
		$out .= qq{<table border="0" width="$width" cellpadding=0 cellspacing=0><tr>};
		$out .= qq{<td align="right" width="$indent" valign="middle">};
	    }
            $out .= $name ? qq{<span class="$label">} . $lang->maketext($name) . ':</span>' : '';
	    $out .= "<br />" if (!$useTable && $name);
	    $out .= qq{</td>\n<td width=4><img src="/media/images/spacer.gif" width=4 height=1 />}
	      if ($useTable); # && $agent->{browser} eq "Netscape");
	    $out .= &$rem_sub($width-4, $indent) if $useTable;
	    $key = escape_html($key) if $key;

	    if (!$readOnly) {
		$js = $js ? " $js" : '';
		$out .= qq{<select name="$key" };
		$out .= 'size="' . ($vals->{props}{size} ||
		  ($vals->{props}{multiple} ? 5 : 1)) . '"';
		$out .= ' multiple' if $vals->{props}{multiple};
		$out .= "$js>\n";
	    }

	    # Make the values a reference if this is a multiple select list.
	    $value = { map { $_ => 1 } split /__OPT__/, $value }
	      if $vals->{props}{multiple};

	    # Iterate through values to create options.
	    my $values = $vals->{props}{vals};
	    my $ref = ref $values;
	    if ($ref eq 'HASH') {
		foreach my $k (sort { $values->{$a} cmp $values->{$b} } keys %$values) {
		    if (!$readOnly) {
			$out .= &$opt_sub($k, $values->{$k}, $value);
		    } else {
			$out .= $values->{$k} . "<br />" if ($values->{$k} eq $value);
		    }
		}
	    } elsif ($ref eq 'ARRAY') {
		foreach my $k (@$values ) {
		    my ($f, $v) = ref $k ? @$k : ($k, $k);
		    if (!$readOnly) {
			$out .= &$opt_sub($f, $v, $value);
		    } else {
			$out .= $v . "<br />" if ($f eq $value);
		    }
		}
	    }

	    $out .= "</select>" if (!$readOnly);

	    $out .= "\n</td></tr></table>\n" if $useTable;
	    # close select
	    $m->out("$out");
	},

 	radio => sub {
	    my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
		$label, $readOnly, $agent) = @_;
	    my $out = '';
	    # print caption for the group
	    if ($useTable) {
		$out .= ($readOnly) ? qq{<table border="0" width="$width"><tr><td width=$indent align="right"> }
	                            : qq{<table border="0" width="$width" cellspacing=0 cellpadding=2><tr><td align="right" width=$indent> };
	    }
	    $out .= qq{<span class="radioLabel">}. $lang->maketext($name) . '</span>' if $name;

	    if ($readOnly) {
		$out .= "</td><td width=" . ($width - $indent) . ">";
		# Find the selected value
		my $values = $vals->{props}{vals};
		my $ref = ref $values;
		if ($ref eq 'HASH') {
		    foreach my $k (sort { $values->{$a} cmp $values->{$b} }
				   keys %$values) {
			$out .= $values->{$k} if ( $value eq $values->{$k});
		    }
		} elsif ($ref eq 'ARRAY') {
		    foreach my $k (@$values ) {
			$k = [$k, $k] unless ref $k;
			$out .= $k->[1] if ($value eq $k->[0]);
		    }
		}
	    } else {
		$out .= "</td><td width=" . ($width - $indent) .">&nbsp;" if ($useTable);
	    }

	    $out .= "</td></tr></table>" if ($useTable);
	    $m->out($out);

	    if (!$readOnly) {
		# Iterate through the values and draw each button:
		my $values = $vals->{props}{vals};
		my $ref = ref $values;
		if ($ref eq 'HASH') {
		    foreach my $k (sort { $values->{$a} cmp $values->{$b} }
				   keys %$values) {
			&$inpt_sub('radio', $key, {}, $k, $js, $values->{$k},
				   $width, $indent, $useTable, $label, $readOnly, $agent,
				   $value eq $k ? ' checked' : '');
			$m->out("<br />\n") if (!$useTable);
		    }
		} elsif ($ref eq 'ARRAY') {
		    foreach my $k (@$values ) {
			$k = [$k, $k] unless ref $k;
			&$inpt_sub('radio', $key, $k->[0], $k->[0], $js, $k->[1],
				   $width, $indent, $useTable, $label, $readOnly, $agent,
				   $value eq $k->[0] ? ' checked' : '');
			$m->out("<br />\n") if (!$useTable);
		    }
		}
	    }
	},
	single_rad => sub {
            my ($key, $vals, $value, $js, $name) = @_;
	    if (exists $vals->{props}{chk}) {
		push @_, ' checked' if $vals->{props}{chk}
	    } elsif ($value) {
		push @_, ' checked';
	    }
	    &$inpt_sub('radio', @_);
	}
);

</%once>

