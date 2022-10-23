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
      # comment this out and ->discard_changes will die at trying to inflate an invalid date:
      create_date => undef,
      email       => 'foo@bar.com',
      pass        => 'foobar',
    }), $name => '$person'
  );

}

=head2 dates

Test the automatic features of timestamps in MySQL

The most logical thing would be to have:

    `create_date` timestamp NOT NULL default CURRENT_TIMESTAMP,
    `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,

This would automatically set the record's I<create_date> and make the
I<update_date> C<NULL> on create. Then updates would leave the I<create_date>
as-is and atomatically set the I<update_date> on subsequent updates.

But MySQL can't have two timestamps with C<CURRENT_TIMESTAMP> in the definition!

So we are using this:

    `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
    `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,

This does everything described above B<EXCEPT> that you have to set
I<create_date> to C<NULL> when C<INSERT>ing a record in the database.

The code in this method excercises the behavior described above.

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
