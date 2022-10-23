use warnings;
use strict;

package WaveRight::DfvProfile::API::Account;
use base qw(WaveRight::DfvProfile);

sub login {
  my $self = shift;

  $self->login_email;
  $self->login_pass;
  $self->remember;
}

sub signup {
  my $self = shift;

  $self->person_name;
  $self->signup_email;
  $self->signup_pass;
  $self->signup_pass_match;
}

1;
