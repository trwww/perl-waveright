# ABSTRACT: WaveRight API Controller
package WaveRight::Catalyst::Controller::API;
use JSON::MaybeXS qw(JSON);

=head1 NAME

WaveRight::Catalyst::Controller::API - WaveRight API Account Controller

=head1 VERSION

version 0.01

=head1 DESCRIPTION

...

=cut

BEGIN { $WaveRight::Catalyst::Controller::API::VERSION = '0.01'; }

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use base qw(WaveRight::Catalyst::Controller);

=head1 ACTIONS

=head2 init

=cut

sub init : Path('init') Args(0) {
  my( $self, $c ) = @_;

  my $user = $c->user && $c->user->obj;

  my $json = $c->stash->{json} = {
    ok => JSON->true,
    user => {
      loggedIn => ($user ? JSON->true  : JSON->false   ),
      name     => ($user ? $user->name : 'Unknown User'),
    },
    password => {
      current => undef,
      new     => undef,
      match   => undef,
    },
  };
}

# match /api
sub base :Chained("/") :PathPart("api") :CaptureArgs(0) {}

# match /api (end of chain)
sub root :Chained("base") :PathPart("") :Args(0) {}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Todd Wade.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
