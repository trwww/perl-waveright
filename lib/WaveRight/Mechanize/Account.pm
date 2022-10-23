use warnings;
use strict;

package WaveRight::Mechanize::Account;
use base qw(WaveRight::Mechanize::Base);
use Test::More;

=head1 NAME

WaveRight::Mechanize::Account - WaveRight::Mechanize::Account command interface

=head1 DESCRIPTION

tools for running administrative account http requests

=head1 METHODS

=head2 enable_webhook

=cut

sub sync_tickets_to_customers : Test(3) {
  my $self = shift;

  my $response = $self->post('/api/account/sync_tickets_to_customers');

  isa_ok( $response => 'HTTP::Response', '$response' );
  isa_ok( my $json = $response->json => 'HASH', '$json' );
  is($json->{ok}, 1, 'ticket syncer returned success');
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
