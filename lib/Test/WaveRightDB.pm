use strict;
use warnings;

package Test::WaveRightDB;
use base qw(Test::WaveRight);
use Test::More;

=head1 NAME

Test::WaveRightDB - Stub class in case code ever needs placed between the test and the
parent class L<Test::WaveRight>.

=head1 DESCRIPTION

Stub parent class

=head1 METHODS

=head2 setup

setup method is run before every test method

=cut

sub setup : Test(setup => +1) {
  my $self = shift;
  $self->next::method( @_ );

  $self->setup_user;
}

=head2 setup_user

store system user object in test object

=cut

sub setup_user {
  my $self          = shift;
  my $c             = $self->{c};
  my $persons_model = $self->model( class => 'Persons' );

  my $user          = $c->model( $persons_model )->search({
	email => $c->config->{SYSTEM_USER}{credentials}{email}
  })->single;

  my $persons_name = $self->model( name => 'Persons' );
  isa_ok( $user => $persons_name => '$user' );
  $self->{user} = $user;  
}


=head2 teardown

teardown method is run after every test method.

=cut

sub teardown : Test(teardown => +1) {
  my $self = shift;

  ok( delete $self->{user} => 'cleared out test user' );
  $self->next::method( @_ );
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
