use strict;
use warnings;

package Test::WaveRightDB::Result::Groups;
use base qw(Test::WaveRightDB);
use Test::More;

=head1 NAME

Test::WaveRightDB::Result::Groups - WaveRightDB::Result::Groups test file

=head1 DESCRIPTION

Pattern and workflow examples for the WaveRightDB::Result::Groups model

=head1 METHODS

=head2 setup

=cut

sub setup : Test(setup => +1) {
  my $self = shift;
  $self->next::method;
  my $c = $self->{c};

  # set up some reused concatenation
  my $class = $self->{app}{test}{class} = $self->{app}{model}{class} . 'Groups';
  my $name  = $self->{app}{test}{name}  = $self->{app}{model}{name}  . 'Groups';

  isa_ok(
    my $group = $self->{group} = $c->model($class)->create({
      name  => 'foo',
      group => 1,
    }),
    $name => '$group'
  );
}

=head2 add_new_child_to_parent

=cut

sub add_new_child_to_parent : Test(1) {
  my $self = shift;
  my $c = $self->{c};

  my $group = $self->{group};

  isa_ok(
    my $child = $self->{child} = $group->add_to_groups({
      name => 'child group',
    }),
    $self->{app}{test}{name} => '$child'
  ); 
}

=head2 add_existing_child_to_parent

=cut

=for TODO

sub add_existing_child_to_parent : Test(XX) {
  my $self = shift;
  my $c = $self->{c};

  my $group = $self->{group};

  $parent = ... # retrieve parent group from db

  # trying to do this in another test didnt seem to be working as expected
  # chose an alternate syntax, but how to do this will need defined soon:
  ok $parent->add_to_groups($group), ...;
}

=head2 add_parent_to_child

=cut

sub add_parent_to_child : Test(3) {
  my $self = shift;
  my $c = $self->{c};

  my $group = $self->{group};

  isa_ok(
    my $child = $self->{child} = $c->model($self->{app}{test}{class})->create({
      name  => 'child group',
      group => 1,
    }),
    $self->{app}{test}{name} => '$child'
  );

  ok( $child->group($group), '$child->group($group) returned true' );
  ok( $child->update, 'call ->update after calling ->col($val)' );
}

=head2 teardown

=cut

# teardown methods are run after every test method.
sub teardown : Test(teardown => +3) {
  my $self = shift;

  my $group = $self->{group};
  my $child = $self->{child};

  is(
    $child->group->id => $group->id,
    'parent <-> child group relationship verified'
  );

  ok($child && $child->delete, 'remove child from database');
  ok($group && $group->delete, 'remove group from database');

  $self->next::method;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
