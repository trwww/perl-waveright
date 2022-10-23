use warnings;
use strict;

package WaveRightDB::ResultSet::GroupsSet;
use base 'DBIx::Class::ResultSet';

sub grouped_create {
  my($self, $subtable) = @_;

  my $groups_source  = $self->result_source->schema->source( 'Groups' );
  my $group          = {};

  foreach my $key ( keys %$subtable ) {
    if ( $groups_source->has_column( $key ) ) {
      $group->{$key} = delete $subtable->{$key};
    }
  }

  unless ( $group->{group} ) {
    die "parent group missing";
  }

  # get create_date to init to current time
  $group->{create_date} = undef unless $group->{create_date};

  $subtable->{group} = $group;

  return $self->create( $subtable );
}

sub grouped_search {
  print "I'm in grouped_search";
}

1;
