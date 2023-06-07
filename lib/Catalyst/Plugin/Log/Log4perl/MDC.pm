use warnings;
use strict;

use Data::GUID;

package Catalyst::Plugin::Log::Log4perl::MDC;
our $VERSION = '1.00';

use namespace::autoclean;
use Moose::Role;
use MooseX::Mangle;

after 'setup_finalize' => sub {
  Catalyst::Utils::ensure_class_loaded('Log::Log4perl::MDC');
};

mangle_return 'prepare' => sub {
  my ($class, $c) = @_;

  my $config = $c->config->{'Plugin::Log::Log4perl::MDC'} || {};
  my $path   = $c->req->uri->path;
  my $userid = 'ANONYMOUS';
  my $sessionid;

  # mechanism to avoid spamming the session table with records
  foreach my $regex ( keys %$config ) {
    if ( $path =~ m|$regex| ) {
      $sessionid = $config->{$regex};
      last;
    }
  }

  if ( ! $sessionid ) {
    my $session = $c->session; # force app to load session
    $sessionid  = $c->sessionid;

    if ( my $auth = $c->user ) {
      my $user = $auth->obj;
      $userid  = $user->id;

      # set user in schema - not just MDC any more
      my $model = sprintf '%sDB', $c->config->{name};
      $c->model( $model )->schema->current_user( $user );
    }
  }

  my $guid = Data::GUID->new->as_string;

  Log::Log4perl::MDC->put(userid    => $userid);
  Log::Log4perl::MDC->put(sessionid => $sessionid);
  Log::Log4perl::MDC->put(guid      => $guid);

  return $c;
};

1;
