use strict;
use warnings;

package Test::WaveRightDB::Result::Persons;
use base qw(Test::WaveRightDB);
use Test::More;

=head1 NAME

Test::WaveRightDB::Result::Persons - WaveRightDB::Result::Persons test file

=head1 DESCRIPTION

Pattern and workflow examples for the WaveRightDB::Result::Persons model

=head1 METHODS

=head2 setup

=cut

sub setup : Test(setup => +2) {
  my $self = shift;
  $self->next::method;
  my $c = $self->{c};

  # set up some reused concatenation
  my $class = $self->{app}{test}{class} = $self->{app}{model}{class} . 'Persons';
  my $name  = $self->{app}{test}{name}  = $self->{app}{model}{name}  . 'Persons';

  isa_ok(
    my $model = $c->model($class),
    'DBIx::Class::ResultSet' => '$model'
  );

  # have to call discard_changes to go back to the db to get create date
  # http://search.cpan.org/~ribasushi/DBIx-Class-0.08109/lib/DBIx/Class/Manual/FAQ.pod#Inserting_and_updating_data
  isa_ok(
    $self->{person} = $model->create({
      email       => 'foo@bar.com',
      pass        => 'foobar',
    }), $name => '$person'
  );

}

=head2 dates

don't have to mention create_date in the ->create calls anymore because mysql 8
handles it for you

=cut

sub dates : Test(8) {
  my $self   = shift;
  my $person = $self->{person};

  my $model_name = $self->{app}{test}{name};

  ok(! $person->create_date, '->create_date null in the obj but set in the db');

  # this goes back to the db and refreshes the fields
  isa_ok($person = $person->discard_changes, $model_name => '$person');

  # create_date is now set
  isa_ok($person->create_date, DateTime => '$person->create_date');

  ok( ! $person->update_date, '->update_date is null' );

  ok(
    $person->update({
      name => 'Test Person',
    }) => 'update returned true'
  );

  ok(! $person->update_date, '->update_date null in the obj but set in the db');

  # this goes back to the db and refreshes the fields
  isa_ok($person = $person->discard_changes, $model_name => '$person');

  # update_date is now set
  isa_ok($person->update_date, DateTime => '$person->update_date');

}

=head2 password

=cut

sub password : Test(2) {
  my $self   = shift;
  my $person = $self->{person};

  is($person->verify_password('barfoo') => 0, 'wrong password returns 0');

  is($person->verify_password('foobar') => 1, 'correct password returns 1');
}

=head2 teardown

=cut

# teardown methods are run after every test method.
sub teardown : Test(teardown => +1) {
  my $self   = shift;
  my $person = $self->{person};

  ok($person->delete, 'remove object from database');

  $self->next::method;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
