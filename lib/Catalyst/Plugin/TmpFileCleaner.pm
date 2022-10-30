use warnings;
use strict;

package Catalyst::Plugin::TmpFileCleaner;
our $VERSION = '1.00';

use namespace::autoclean;
use Moose::Role;

after 'finalize' => sub {
  my $c    = shift;

  if ( $ENV{MOD_PERL} and (ref $c->req->body eq 'File::Temp') ) {
    $c->req->_clear_body;
  }
};

1;
