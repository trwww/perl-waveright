use warnings;
use strict;

package WaveRight::Mechanize::Base;
use base qw(Test::WaveRight);
use Test::More;

=head1 NAME

WaveRight::Mechanize::Base - WaveRight::Mechanize::* base class

=head1 DESCRIPTION

Base class for WaveRight::Mechanize::* runners

=head1 METHODS

=head2 startup

Logs in administrative assistant user w/ credentials from config

All Mechanize tests assume we have the admin user logged in

=cut

# startup methods are run once before tests.
sub startup : Test(startup => 3) {
  my $self = shift;

  $self->next::method( @_ );

  $self->load_mech;
  $self->log_in;  
}

=head2 shutdown

Explicitly undefines the mechanize object created in the startup method.

=cut

# shutdown methods are run once after tests.
sub shutdown : Test(shutdown) {
  my $self = shift;

  $self->log_out;
  $self->{mech} = undef;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
