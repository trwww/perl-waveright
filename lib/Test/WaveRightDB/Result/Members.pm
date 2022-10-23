use strict;
use warnings;

package Test::WaveRightDB::Result::Members;
use base qw(Test::WaveRightDB);
use Test::More;

=head1 NAME

Test::WaveRightDB::Result::Members - WaveRightDB::Result::Members test file

=head1 DESCRIPTION

Pattern and workflow examples for the WaveRightDB::Result::Members model

=head1 METHODS

=head2 setup

=cut

sub setup : Test(setup => +4) {
  my $self = shift;
  $self->next::method;
  my $c = $self->{c};

  my $class = $self->{app}{model}{class};
  my $name  = $self->{app}{model}{name};

  isa_ok(
    my $person = $self->{person} = $c->model($class . 'Persons')->create({
      email       => 'foo@bar.com',
      pass        => 'foobar',
      create_date => undef,
    }),
    $name . 'Persons' => '$person'
  );

  isa_ok(
    my $group = $self->{group} = $c->model($class . 'Groups')->create({
      name        => 'foo',
      create_date => undef,
    }),
    $name . 'Groups' => '$group'
  );  

  ok(
    ! grep($_->id == $group->id, $person->groups),
    q|group is not in person's groups|
  );

  ok(
    ! grep($_->id == $person->id, $group->persons),
    q|person is not in groups's memberships|
  );
}

=head2 members

example for doing a person <-> group relationship with the mapping table directly

=cut

sub members : Test(3) {
  my $self = shift;
  my $c = $self->{c};

  my $person = $self->{person};
  my $group = $self->{group};

  my $class = $self->{app}{model}{class};
  my $name  = $self->{app}{model}{name};

  isa_ok(
    my $member = $self->{member} = $c->model($class . 'Members')->create({
      person       => $person,
      group        => $group,
      create_date  => undef,
    }),
    $name . 'Members' => '$member'
  );

  isa_ok(
    my $memberships = $person->members,
    'DBIx::Class::ResultSet' => '$memberships'
  );

  is($member->id, $memberships->first->id, 'membership id matches');
}

=head2 add_to_groups

adds a group to a person

=cut

sub add_to_groups : Test(1) {
  my $self = shift;
  my $c = $self->{c};

  my $person = $self->{person};
  my $group = $self->{group};

  isa_ok(
    my $member = $self->{member} = $person->add_to_groups($group, {
      create_date  => undef,
    }),
    $self->{app}{model}{name} . 'Members' => '$member'
  ); 
}

=head2 add_to_persons

adds a person to a group

=cut

sub add_to_persons : Test(1) {
  my $self = shift;
  my $c = $self->{c};

  my $person = $self->{person};
  my $group = $self->{group};

  isa_ok(
    my $member = $self->{member} = $group->add_to_persons($person, {
      create_date  => undef,
    }),
    $self->{app}{model}{name} . 'Members' => '$member'
  ); 
}

=head2 isMember

=cut

sub isMember : Test(10) {
  my $self   = shift;
  my $c      = $self->{c};
  my $person = $self->{person};
  my $group  = $self->{group};

  my $class = $self->{app}{model}{class};
  my $name  = $self->{app}{model}{name};

  ok(
    ! $person->isMember($c, $group),
    '->isMember returns false without a membership'
  ); 

  isa_ok( # tcg == teardown_test_group
    my $managers = $self->{tcg} = $c->model($class . 'Groups')->find( $c->config->{roles}{manager} ),
    $name . 'Groups' => '$managers'
  );

  ok($group->group($managers), 'made managers group parent of test group');
  ok($group->update, 'have to run update to send new data to db');

  ok(! $person->isMember($c, $group), 'test user is not in manager group yet');

  isa_ok(
    my $member = $self->{member} = $managers->add_to_persons($person, {
      create_date => undef,
    }),
    $name . 'Members' => '$member'
  ); 

  isa_ok(
    my $check = $person->isMember($c, $group),
    $name . 'Members' => '$check'
  ); 

  is(
    $member->id, $check->id,
    'found user in manager group via isMember'
  );

  isa_ok(
    my $customers = $c->model($class . 'Groups')->find( $c->config->{roles}{customer} ),
    $name . 'Groups' => '$customers'
  );

  ok(! $person->isMember($c, $customers), 'test user is not in customers subgroups');
}

=head2 isDescendant

=cut

sub isDescendant : Test(10) {
  my $self   = shift;
  my $c      = $self->{c};
  my $person = $self->{person};
  my $group  = $self->{group};

  my $class = $self->{app}{model}{class};
  my $name  = $self->{app}{model}{name};

  isa_ok(
    my $managers = $c->model($class . 'Groups')->find( $c->config->{roles}{manager} ),
    $name . 'Groups' => '$managers'
  );

  isa_ok(
    my $customers = $c->model($class . 'Groups')->find( $c->config->{roles}{customer} ),
    $name . 'Groups' => '$customers'
  );

  isa_ok(
    my $app = $c->model($class . 'Groups')->find( $c->config->{roles}{ lc $c->config->{name} } ),
    $name . 'Groups' => '$app'
  );

  ok($group->group($customers), q|made customers group parent of test group|);
  ok($group->update, 'have to run update to send new data to db');

  ok(
    ! $person->isDescendant($c, $customers),
    'test user is not a customer descendant yet'
  );

  isa_ok(
    my $member = $self->{member} = $group->add_to_persons($person, {
      create_date  => undef,
    }),
    $name . 'Members' => '$member'
  ); 

  ok(
    $person->isDescendant($c, $app),
    'person is in app group or descendant of app group'
  );

  ok(
    $person->isDescendant($c, $customers),
    'person is in customers group or descendant of customers group'
  );

  ok(
    ! $person->isDescendant($c, $managers),
    'person is NOT related to managers group'
  );
}

=head2 get_schema_from_person

=cut

sub get_schema_from_person : Test(4) { # runs a test from add_to_persons
  my $self   = shift;

  $self->add_to_persons; # add person to group to teardown dosent fail

  my $c      = $self->{c};
  my $person = $self->{person};
  my $group  = $self->{group};

  isa_ok(
    my $result_source = $person->result_source,
    'DBIx::Class::ResultSource::Table' => '$result_source'
  );

  isa_ok(
    my $schema = $result_source->schema,
    $self->{app}{name} . 'DB' => '$schema'
  );

  my $model = $self->{app}{model}{name} . 'Groups';
  isa_ok(
    my $admins = $schema->resultset($model)->find( $group->id ),
    $model => '$admins'
  );

}

=head2 teardown

=cut

# teardown methods are run after every test method.
sub teardown : Test(teardown => +5) {
  my $self = shift;

  my $member = $self->{member};
  my $person = $self->{person};
  my $group = $self->{group};

  my $tcg = delete($self->{tcg}) || $group;

  ok(
    grep($_->id == $tcg->id, $person->groups),
    q|found group in person's groups|
  );

  ok(
    grep($_->id == $person->id, $tcg->persons),
    q|found person in groups's memberships|
  );

  ok($member && $member->delete, 'remove member from database');
  ok($person && $person->delete, 'remove person from database');
  ok($group && $group->delete, 'remove group from database');

  $self->next::method;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
