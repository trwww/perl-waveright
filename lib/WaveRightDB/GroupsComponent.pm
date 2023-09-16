use warnings;
use strict;

package WaveRightDB::GroupsComponent;
use Log::Contextual qw( :log );

sub grouped_update {
  my( $self, $data ) = @_;

  $self->result_source->schema->txn_do( \&_txn_grouped_update,
    $self, $data
  );

  return 1;
}

use Clone ();
sub _txn_grouped_update {
  my( $self, $input ) = @_;

  # shallow copy so we're not effecting caller's data
  my $data = { %$input };

  # never let an id field get to ->update calls
  if ( exists $data->{id} ) {
    my $id = delete $data->{id};
    log_warn { sprintf 'grouped_update was passed an id field: [%s]', $_[0] } $id;
  }

  my $groups_source  = $self->result_source->schema->source( 'Groups' );
  my $group          = {};

  # move fields that are group table fields to a different hash
  foreach my $key ( keys %$data ) {
    if ( $groups_source->has_column( $key ) ) {
      $group->{$key} = delete $data->{$key};
    }
  }

  $self->group->update( $group ) if keys %$group;
  $self->update( $data ) if keys %$data;
}

sub grouped_delete {
  my $self = shift;

  $self->result_source->schema->txn_do( \&_txn_grouped_delete, $self );

  return 1;
}

sub _txn_grouped_delete {
  my $self = shift;

  # delete data specific to subtable
  $self->_subdata_delete;

  # delete subgroup memberships
  my $subgroups = $self->groups;
  while ( my $subgroup = $subgroups->next ) {
    $subgroup->members->delete;
  }

  # and then the sugroups themselves
  $subgroups->delete;

  # delete the subtable record and finally the group record
  my $group = $self->group;
  $self->delete;
  $group->delete;
}

# no-op sub so _txn_grouped_delete doesn't have to call ->can
sub _subdata_delete {}

=head2 create_date

=cut

sub create_date {
  my $self = shift;
  return $self->group->create_date;
}

=head2 update_date

=cut

sub update_date {
  my $self = shift;
  return $self->group->update_date;
}

=head2 groups

=cut

sub groups {
  my $self = shift;
  return $self->group->groups;
}

=head2 location

=cut

sub location {
  my $self = shift;
  return $self->group->location;
}

=head2 phone

=cut

sub phone {
  my $self = shift;
  return $self->group->phone;
}

=head2 name

=cut

sub name {
  my $self = shift;
  return $self->group->name;
}

=head2 order

=cut

sub order {
  my $self = shift;
  return $self->group->order;
}

=head2 subgroup

=cut

sub subgroup {
  my $self = shift;
  return $self->group->subgroup( @_ )->first;
}

1;
