<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/footer.mc" &>

=head1 DESCRIPTION

Finish off the HTML.

=cut
</%doc>
% if (Bric::Config::QA_MODE) {
<& '/widgets/debug/debug.mc', %{$ARGS{param}} &>
% }
    </div> <!-- end #contentContainer -->
</div> <!-- end #mainContainer -->
</body>
</html>

