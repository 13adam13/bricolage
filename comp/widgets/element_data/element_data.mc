<table border="0" width="578">
% foreach my $typearr (@{ $conf{$meta->{'type'}} }) {
<tr><td valign="top" width="578">
<& $typearr->[2], $typearr &>
</td></tr>
% }
</table>
<%def .text>
<& '/widgets/profile/text.mc', 'name' => $_[0]->[0],
    'value' => $meta->{$_[0]->[0]}, 'disp' => $_[0]->[1],
    'size' => 32 &>
</%def>
<%def .number>
<& '/widgets/profile/text.mc', 'name' => $_[0]->[0],
    'value' => $meta->{$_[0]->[0]}, 'disp' => $_[0]->[1],
    'size' => 3 &>
</%def>
<%def .textarea>
<& '/widgets/profile/textarea.mc', 'name' => $_[0]->[0],
   'value' => $meta->{$_[0]->[0]}, 'disp' => $_[0]->[1],
   'rows' => 5, 'cols' => 20 &>
</%def>
<%def .check>
<& '/widgets/profile/checkbox.mc', 'name' => $_[0]->[0],
    'value' => $meta->{'value'}, 'disp' => $_[0]->[1],
    'checked' => $meta->{$_[0]->[0]} &>
</%def>
<%args>
$field
</%args>
<%shared>
my ($meta, %conf);
</%shared>
<%init>
my $textStyle    = 'style="width:120px"';
my $textareaRows = 5;
my $textareaCols = 20;

# shared
$meta = $field->get_meta('html_info');

# Note: don't confuse $meta->{'disp'} with a row in %conf 
# beginning with 'disp'

%conf = (
    # XXX: how this turned into a hash of 2-d arrays, i'm not sure...
    # feel free to change it to something better
    'text' => [
        ['disp' => 'Label', '.text'],
        ['value' => 'Default Value', '.text'],
        ['size' => 'Size', '.number'],
        ['maxlength' => 'Maximum size', '.number'],
    ],
    'radio' => [
        ['disp' => 'Group Label', '.text'],
        ['value' => 'Default Value', '.text'],
        ['vals' => 'Options, Label', '.textarea'],
    ],
    'checkbox' => [
        ['disp' => 'Label', '.text'],
    ],
    'pulldown' => [
        ['disp' => 'Label', '.text'],
        ['value' => 'Default Value', '.text'],
        ['vals' => 'Options, Label', '.textarea'],
    ],
    'select' => [
        ['disp' => 'Label', '.text'],
        ['value' => 'Default Value', '.text'],
        ['size' => 'Size', '.number'],
        ['vals' => 'Options, Label', '.textarea'],
        ['multiple' => 'Allow multiple', '.check'],
    ],
    'textarea' => [
        ['disp' => 'Label', '.text'],
        ['value' => 'Default Value', '.text'],
        ['maxlength' => 'Max size', '.number'],
        ['rows' => 'Rows', '.number'],
        ['cols' => 'Columns', '.number'],
    ],
    'date' => [
        ['disp' => 'Caption', '.text'],
    ],
);
</%init>
