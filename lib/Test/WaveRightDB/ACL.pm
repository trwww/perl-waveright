use strict;
use warnings;

package Test::WaveRightDB::ACL;
use base qw(Test::WaveRightDB);
use Test::More;

=head1 NAME

Test::WaveRightDB::ACL - WaveRightDB::ACL test file

=head1 DESCRIPTION

ACL tests

=head1 METHODS

=head2 no_user

=cut

sub no_user : Test(6) {
  my $self = shift;
  my $c    = $self->{c};

  # role data structure
  is( $c->check_user_roles('administrator')->{error} =>            'No logged in user', 'expected error for administrator role test' );
  is( $c->check_user_roles('manager')->{error} =>                  'No logged in user', 'expected error for manager role test' );
  is( $c->check_user_roles('administrator', 'manager')->{error} => 'No logged in user', 'expected error for (administrator,manager) role test' );

  # boolean test on $c->check_user_roles('...')->{granted}
  is( $c->has_roles('administrator')            => 0, 'expected boolean for administrator role test' );
  is( $c->has_roles('manager')                  => 0, 'expected boolean for manager role test' );
  is( $c->has_roles('administrator', 'manager') => 0, 'expected boolean for (administrator,manager) role test' );

}

=head2 administrator

=cut

sub administrator : Test(8) {
  my $self = shift;
  my $c    = $self->{c};

  isa_ok(my $user = $c->find_user({ id => 5 }) => 'Catalyst::Authentication::Store::DBIx::Class::User' => '$user' );
  $c->set_authenticated( $user );

  is( $c->check_user_roles('administrator')->{granted}            => 1     , 'user is an administrator' );
  is( $c->check_user_roles('manager')->{granted}                  => undef , 'user is not a manager' );
  is( $c->check_user_roles('administrator', 'manager')->{granted} => 1     , 'has access as administrator' );

  is( $c->has_roles('administrator')            => 1 , 'boolean for user is an administrator' );
  is( $c->has_roles('manager')                  => 0 , 'boolean for user is not a manager' );
  is( $c->has_roles('administrator', 'manager') => 1 , 'boolean for has access as administrator' );

  ok(! $c->logout => 'logged out user');
}

=head2 manager

=cut

sub manager : Test(8) {
  my $self = shift;
  my $c    = $self->{c};

  isa_ok(my $user = $c->find_user({ id => 6 }) => 'Catalyst::Authentication::Store::DBIx::Class::User' => '$user' );
  $c->set_authenticated( $user );

  is( $c->check_user_roles('administrator')->{granted}            => undef , 'user is not an administrator' );
  is( $c->check_user_roles('manager')->{granted}                  => 1     , 'user is a manager' );
  is( $c->check_user_roles('administrator', 'manager')->{granted} => 1     , 'has access as manager' );

  is( $c->has_roles('administrator')            => 0 , 'boolean for user is not an administrator' );
  is( $c->has_roles('manager')                  => 1 , 'boolean for user is a manager' );
  is( $c->has_roles('administrator', 'manager') => 1 , 'boolean for has access as manager' );

  ok(! $c->logout => 'logged out user');
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
