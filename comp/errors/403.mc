<%perl>;
# Clear out messages and buffer - they're likely irrelevant now.
clear_msg();
$m->clear_buffer;
$m->comp('/widgets/wrappers/sharky/header.mc',
	 title => 'Permission Denied',
	 context => '',
	 debug => QA_MODE);
my $name = ref $obj ? $obj->get_name : '';
my $the = '';
if ($name) {
    $name = '&quot;' . $name . '&quot;';
    $the = 'the';
}
my $class = ref $obj;
if ($class) {
    $class = get_disp_name($class) . ' object';
} elsif ($obj) {
    $class = get_disp_name($obj);
    $class .= ' objects' if $class;
} else {
    $class = 'this page';
}
$m->out('<p class="header">',
        $lang->maketext('You have not been granted <b>[_1]</b> ' .
                        'access to the <b>[_2]</b> [_3]',
                        $map->{$perm}, $name, $class),
        "</p>\n");
$m->comp('/widgets/wrappers/sharky/footer.mc');
$m->abort;
</%perl>
<%args>
$perm => undef
$obj => undef
</%args>
<%once>;
my $map = Bric::Util::Priv->vals_href;
</%once>
