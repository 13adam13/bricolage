package Bric::Util::Grp::AssetLanguage;

sub get_secret { 1 };

1;
__END__

=head1 NAME

Bric::Util::Grp::AssetLanguage - Legacy Group Class

=head1 DESCRIPTION


This is a dummy class to keep upgraded installations from breaking when
Bric::Util::Grp loads classes based on the contents of the contents of the
Class table. Unfortunately trying to delete from the Class table triggeres a
cascading delete of dangerous proportions. If we find a way around that then
we can remove this file.

=cut
