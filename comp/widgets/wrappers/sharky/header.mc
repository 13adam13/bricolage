<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/header.mc" &>

=head1 DESCRIPTION

HTML wrapper for top and side navigation.

=cut

</%doc>
<%args>
$title   => get_pref('Bricolage Instance Name')
$jsInit  => ""
$context
$useSideNav => 1
$no_toolbar => NO_TOOLBAR
$no_hist => 0
$debug => undef
</%args>
<%init>;
$context =~ s/\&quot\;/\"/g;
my @context =  split /\|/, $context;

for (@context){
    s/^\s+//g;
    s/\s+$//g;
    if (/^(\"?)(.+?)(\"?)$/) {
        my ($startquote, $text, $endquote) = ($1, $2, $3);
        $text =~ s/([\[\],~])/~$1/g;
        $_ = qq{$startquote<span class="110n">}
          . $lang->maketext($text) . "</span>$endquote";
    }
}

$context = join ' | ', @context;

# Figure out where we are (assume workflow).
my ($section, $mode, $type) = parse_uri($r->uri);
$section ||= 'workflow';

my ($properties);
my @title       = split (/ /, $title);
my $uri         = $r->uri;

if(ref($title) eq 'ARRAY') {
    $title = $lang->maketext(@$title);
} else {
    # clean up the title
    $title = $lang->maketext( join ' ', map { ucfirst($_) } split / /, $title);
}

</%init>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<link rel="stylesheet" type="text/css" href="/media/css/style.css" />
<link rel="stylesheet" type="text/css" href="/media/css/<% $lang_key %>.css" />
<title><% $title %></title>
% if ($useSideNav) {
<script type="text/javascript" src="/media/js/lib.js"></script>
<script type="text/javascript" src="/media/js/<% $lang_key %>_messages.js"></script>
% }
<script type="text/javascript">

var lang_key = "<% $lang_key %>";
var checkboxValues = new Array();

window.onload = function () {
    init();
    installHelpButtons();
}

function init() {
    <% $jsInit %>;
}

% if ($no_toolbar) {
if (window.name != 'Bricolage_<% SERVER_WINDOW_NAME %>') {
    // Redirect to the window opening page.
    location.href = '/login/welcome.html?referer=<% $r->uri %>';
} else {
    history.forward(1);
}
% } # if
</script>
</head>

<body>
<noscript>
<h1><% $lang->maketext("Warning! Bricolage is designed to run with JavaScript enabled.") %></h1>
<p><% $lang->maketext('Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.') %></p>
</noscript>

<!-- begin top table -->
<div id="bricLogo">
% if ($useSideNav) {
        <a href="#" title="About Bricolage" id="btnAbout"><img src="/media/images/<% $lang_key %>/bricolage.gif" /></a>
% } else {
        <img src="/media/images/<% $lang_key %>/bricolage.gif" alt="Bricolage" />
% }
</div>
<!-- end top tab table -->

<div id="mainContainer">
<%perl>;
# handle the various states of the side nav
if ($useSideNav) {

    if (DISABLE_NAV_LAYER) {
        $m->comp("/widgets/wrappers/sharky/sideNav.mc", debug => $debug);
    } else {
        my $uri = $r->uri;
        $uri .= "&amp;debug=$debug" if $debug;
        # create a unique uri to defeat browser caching attempts.
        $uri .= "&amp;rnd=" . time;
        chomp $uri;
        $m->out( qq{<iframe name="sideNav" id="sideNav" } .
                 qq{        src="/widgets/wrappers/sharky/sideNav.mc?uri=$uri" } .
                 qq{        scrolling="no" frameborder="no"></iframe>} );
    }
}

</%perl>

<!-- begin content area -->
<div id="contentContainer">
% # top tab, help, logout buttons
    <div id="headerContainer">
        <div class="<% $section %>Box">
            <div class="fullHeader">
                <div class="number">&nbsp;</div>
                <div class="caption"><% $title %></div>
                <div class="rightText">&nbsp;</div>
            </div>
        </div>
% if ($useSideNav) {
        <div class="buttons">
            <& "/widgets/buttons/help.mc", context => $context, page => $title &>
            <a href="/workflow/profile/alerts" title="My Alerts"><img src="/media/images/<% $lang_key %>/my_alerts_orange.gif" alt="My Alerts" /></a>
            <a href="/logout" title="Logout"><img src="/media/images/<% $lang_key %>/logout.gif" alt="Logout" /></a>
        </div>
% }
    </div>

% # top message table
    <div id="breadcrumbs">
        <p><% $context %></p>
% if ($useSideNav) {
        <div class="siteContext"><& /widgets/site_context/site_context.mc &></div>
% }
    </div>
<%perl>;
# handle error messaging
while (my $txt = next_msg) {
     # insert whitespace on top to balance the line break the form tag inserts after these messages.
    if ($txt =~ /(.*)<span class="l10n">(.*)<\/span>(.*)/) {
        $txt = escape_html($1) . '<span class="l10n">'
          . escape_html($2) . '</span>' . escape_html($3);
    } else {
        $txt = escape_html($txt);
    }
</%perl>
    <p class="errorBox">
        <span class="errorMsg"><% $txt %></span>
    </p>
% }
