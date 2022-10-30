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

  my $sessionid;

  foreach my $regex ( keys %$config ) {
    if ( $path =~ m|$regex| ) {
      $sessionid = $config->{$regex};
      last;
    }
  }

  unless ( $sessionid ) {
    my $session = $c->session; # force app to load session
    $sessionid  = $c->sessionid;
  }

  my $guid = Data::GUID->new->as_string;

  Log::Log4perl::MDC->put(sessionid => $sessionid);
  Log::Log4perl::MDC->put(guid      => $guid);

  return $c;
};

1;
