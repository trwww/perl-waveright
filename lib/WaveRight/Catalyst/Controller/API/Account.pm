# ABSTRACT: WaveRight Account Controller
package WaveRight::Catalyst::Controller::API::Account;
use JSON::MaybeXS qw(JSON);

=head1 NAME

WaveRight::Catalyst::Controller::API::Account - WaveRight API Account Controller

=head1 VERSION

version 0.01

=head1 DESCRIPTION

...

=cut

BEGIN { $WaveRight::Catalyst::Controller::API::Account::VERSION = '0.01'; }

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use base qw(WaveRight::Catalyst::Controller);

=head1 ACTIONS

=head2 sync_tickets_to_customers

=cut

sub sync_tickets_to_customers : Path('sync_tickets_to_customers') Args(0) {
  my ( $self, $c ) = @_;
  my $app   = $c->config->{name};
  my $model = $app . 'DB';

  my $json = $c->stash->{json} = {
    ok        => JSON->false,
    customers => [],
  }; 

  $c->log->info('sync missing ticket numbers to customers');
  $self->assert_authorization($c => 'manager');

  # customers with no ticket number
  my $customers = $c->model($model . '::Persons')->search({
    'me.ticket'     => undef,
    'members.group' => $app->config->{roles}{customer}
  }, {
    join => 'members',
  });

  while ( my $customer = $customers->next ) {
    $customer->ticket_sync( $c );
    push @{ $json->{customers} } => {
	  id     => $customer->id,
	  ticket => $customer->ticket,
    }
  }

  $json->{ok} = JSON->true;
}

=head2 signup

=cut

sub signup : POST Path('signup') Args(0) Consumes(JSON) {
  my ( $self, $c ) = @_;
  my $params = $c->req->body_data;

  my $json = $c->stash->{json} = {
    ok => JSON->false,
  }; 

  my $signup_profile = $c->model('DfvProfile')->get;

  my $results = $c->stash->{results} = Data::FormValidator->check(
    $params, $signup_profile
  );

  if ( $results->success ) {
    $c->log->info('going to complete user signup');
    $self->complete_signup($c, $results);

    $json->{ok}      = JSON->true;
    $json->{toaster} = {
      type            => 'success',
      title           => 'Sign Up Success',
      body            => 'Account created. You may now log in.',
      showCloseButton => JSON->true,
      timeout         => 7500,        
    };
  } else {
    $c->log->info('signup input invalid');
    $json->{request} = Log::Log4perl::MDC->get('guid');
    $json->{msgs}    = scalar $results->msgs;
    $json->{toaster} = {
      type            => 'error',
      title           => 'Sign Up Error',
      body            => 'Hover over a red field for the exact error message.',
      showCloseButton => JSON->true,
      timeout         => 7500,        
    };
  }
}

=head2 complete_signup

=cut

sub complete_signup {
  my ( $self, $c, $results ) = @_;
  my $model = $c->config->{name} . 'DB';

  my $data = {
    person => {
      name        => scalar $results->valid('name'),
      email       => scalar $results->valid('email'),
      pass        => scalar $results->valid('pass'),
      pass_hint   => scalar $results->valid('pass_hint'),
      create_date => undef,
    },
  };

  my $person = $c->model($model . '::Persons')->create( $data->{person} );

  # have to set the password via accessor because saltedpasswords isn't
  # triggered  in the update above. Maybe look in to fixing saltedpasswords?
  $person->pass( $results->valid('pass') );
  $person->update;

  $c->stash->{verification} = $c->model($model . '::VerificationGuids')->create({
    create_date => undef,
    person      => $person,
    type        => 'new account',
    guid        => Data::GUID->new,
  });

  # add user to customers group
  my $customers = $c->model($model . '::Groups')->find( $c->config->{roles}{customer} );
  $person->add_to_groups( $customers, {
    create_date => undef,
  });

  $c->stash->{person} = $person;

  $self->email_manager( $c => {
    subject  => $c->config->{name} . ' - Welcome! Verify Your Email',
    template => 'email/account/welcome.txt',
    type     => 'correspond',
    person   => $person,
  });
}

=head2 login

logs in user and returns authorization cookie to client

=cut

sub login : POST Path('login') Args(0) Consumes(JSON) {
  my($self, $c) = @_;
  my $params = $c->req->body_data;

  my $json = $c->stash->{json} = {
    ok => JSON->false,
  }; 

  my $login_profile = $c->model('DfvProfile')->get;

  my $results = $c->stash->{results} = Data::FormValidator->check(
    $params, $login_profile
  );

  if ( $results->success ) {
    $c->authenticate({ # assume user exists due to validator success
      email => $results->valid('email'),
      pass  => $results->valid('pass'),
    });

# TODO: wrap this in a config option to turn on RT integration
#    if ( $c->has_roles( 'customer' ) && ! $c->user->obj->ticket ) {
#      $c->run_after_request(sub {
#        my $c = shift;
#        $c->user->obj->ticket_sync( $c );
#      });
#    }

    # http://www.gossamer-threads.com/lists/catalyst/dev/28781#28781
    if ( $results->valid('remember') ) { # remember me checkbox
      $c->set_session_cookie_expire( $c->_session_plugin_config->{expires} );
    }

    my $api = sprintf '%s::Controller::API', $c->config->{name};
    $api->init( $c );
    $json = $c->stash->{json}; # get new json hash that the visit overwrote

    $json->{ok}      = JSON->true;
    $json->{toaster} = {
      type            => 'success',
      title           => 'Log In Success',
      body            => 'You are now logged in and can manage dashboards.',
      showCloseButton => JSON->true,
      timeout         => 7500,        
    };
  } else {
    $c->log->info('login input invalid');
    $json->{request} = Log::Log4perl::MDC->get('guid');
    $json->{msgs}    = scalar $results->msgs;
    $json->{toaster} = {
      type            => 'error',
      title           => 'Log In Error',
      body            => 'Hover over a red field for the exact error message.',
      showCloseButton => JSON->true,
      timeout         => 7500,        
    };
  }
}

=head2 logout

=cut

sub logout : Path('logout') Args(0) {
  my($self, $c) = @_;
  $c->logout();
  $c->set_session_cookie_expire( undef );

  my $api = sprintf '%s::Controller::API', $c->config->{name};
  $api->init( $c );
  my $json = $c->stash->{json}; # get new json hash that the visit overwrote

  $json->{ok}      = JSON->true;
  $json->{toaster} = {
    type            => 'success',
    title           => 'Log Out Success',
    body            => 'You are now logged out.',
    showCloseButton => JSON->true,
    timeout         => 7500,
  };
}

__PACKAGE__->meta->make_immutable;

1;


=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Todd Wade.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
