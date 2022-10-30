use warnings;
use strict;

package Template::Plugin::ListCompare;
use base qw( List::Compare );
use base qw( Template::Plugin );

=head1 NAME

Template::Plugin::ListCompare - List::Compare plugin for TT

=head1 METHODS

=cut

=head2 new

stores the template context in $self->{'_CONTEXT'}

=cut

sub new {
  my($class, $context, @params) = @_;
  my $self = $class->SUPER::new(@params);
  return $self;
}

=head1 AUTHOR

WaveRight Information Technology, LLC

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
