use strict;
use warnings;

package Test::WaveRight::Catalyst::Controller::API::Account;
use base qw(Test::WaveRight);
use Test::More;
use JSON::MaybeXS qw(JSON);

=head1 NAME

Test::WaveRight::Catalyst::Controller::API::Account

=head1 DESCRIPTION

account based tests

=head1 METHODS

=head2 setup

runs before each test

=cut

sub setup : Test(setup => +1) {
  my $self = shift;
  $self->next::method;
  $self->load_mech;
}


=head2 login

bare login test, Test::More tests happen in log_in method

=cut

sub login : Test(1) {
  my $self = shift;

  my $response = $self->log_in;
}

=head2 expected_signup_response

returns expected hash from signing up

=cut

sub expected_signup_response {
  my $self = shift;

  my $expected = {
    ok      => JSON->true,
    toaster => {
      type            => 'success',
      showCloseButton => JSON->true,
      timeout         => 7500,
      body            => 'Account created. You may now log in.',
      title           => 'Sign Up Success',
    }
  };

  return $expected;
}

=head2 signup

Tests signup. Currently sends an email to dev rt server, might want to modify
config here to turn that off?

=cut

sub signup : Test(1) {
  my $self = shift;

  $self->{data} = {
    name       => 'Joe Smith',
    email      => 'foo@bar.com',
    pass       => 'f00b@r',
    pass_match => 'f00b@r',
  };

  my $response = $self->post( '/api/account/signup' => $self->{data});

  diag explain $response->json if $ENV{DIAG};

  my $expect = $self->expected_signup_response;
  is_deeply( $response->json, $expect, 'signup complete' );
}

=head2 setup

runs after each test

=cut

sub teardown : Test(teardown => no_plan) {
  my $self = shift;
  my $c    = $self->{c};

  if ( my $data = delete $self->{data} ) {
    isa_ok( my $user = $c->model( $self->model(class => 'Persons') )->search({
	  email => $data->{email}
    })->single => $self->model(name => 'Persons') => '$user' );

    is($user->members->count => 1, 'found single (assuming customer) membership');
    ok($user->members->delete => 'deleted memberships');
    ok($user->delete, 'deleted user from db');
  }

  $self->next::method;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
