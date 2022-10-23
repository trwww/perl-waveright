use warnings;
use strict;

package WaveRight::Catalyst::Controller;
use JSON::MaybeXS qw(JSON);

=head1 NAME

WaveRight::Catalyst::Controller - Common functionality for WaveRight controllers

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 assert_authorization

=cut

sub assert_authorization {
  my( $self, $c, @roles ) = @_;

  (undef, undef, my $line) = caller();
  (undef, undef, undef, my $subroutine) = caller(1);
  $c->log->info(sprintf 'asserting authorization for %s:%d', $subroutine, $line);

  my $result  = $c->check_user_roles( @roles );
  my $granted = $result->{granted};

  if ( $granted ) {
    $c->log->debug(sprintf 'permission granted [%s]', join ',', @{ $result->{have} });
  } else {
    my $json = $c->stash->{json}{toaster} = {
      type            => 'error',
      title           => 'Permission Denied',
      showCloseButton => JSON->true,
      timeout         => 7500,        
    };

    if ( $result->{error} ) {
      $json->{body} = $result->{error};
      $c->log->info(sprintf 'permission error: %s', $result->{error});
    } else {
      my $message = sprintf 'permission denied: %s', join ',', @{ $result->{roles} };
      $json->{body} = $message;
      $c->log->info($message);
    }

    $c->detach; # assertion exits request
  }
}

=head2 email_manager

on non-live environments we cant send emails to our actual users

so this code will send the email to the devs instead of the actual recipient

$args->{system} sets the from email to the clock rt user so that the user
will get an update on their ticket. If we send the email with the user
as the from address, RT won't send them an email because of NotifyActor

=cut

sub email_manager {
  my($self, $c, $args) = @_;

  my $config    = $c->config->{'View::Email'}{manager};
  my $recipient = delete $args->{person};

  # rt needs the user email address as the from so they can be the requestor
  if ( $args->{system} or ($args->{type} eq 'comment') ) {
    $args->{from} = $config->{rtuser};
  } else {
    $args->{from} = ref $recipient ? $recipient->email : $recipient;
  }

  # set the recipient of the email to the rt queue email address
  $args->{to} = $config->{ $args->{type} };

  $args->{header}  = $self->prepare_headers( $c, $recipient );
  $args->{subject} = $self->prepare_subject( $c, $recipient, $config, $args );

  if ( $config->{debug} ) {
    # move recipients to a different hash
    my @managed_fields = qw(from cc bcc template);
    my @present_managed_fields = grep $args->{$_}, @managed_fields;
    my %managed; @managed{ @present_managed_fields } = map delete $args->{$_}, @present_managed_fields;

    $args->{from} = $config->{rtuser};

    $c->stash->{'debug.email'} = \%managed;

    $args->{body} = $c->view('TT')->render( $c, $managed{template} );
  } else {
    $args->{body} = $c->view('TT')->render( $c, delete $args->{template} );
  }

  $c->stash->{email} = $args;

  if ( $config->{active} ) {
    $c->forward( $c->view('Email') );
  } else {
    $c->log->debug('email sending deactivated in config');
  }
}

=head2 prepare_headers

=cut

sub prepare_headers {
  my( $self, $c, $recipient ) = @_;
  my $app = $c->config->{name};

  my $headers = [];

  if ( ref $recipient ) {
    push @$headers => sprintf('X-%s-Account', uc $app) => $recipient->id;
  }

  return $headers;
}

=head2 prepare_subject

=cut

sub prepare_subject {
  my( $self, $c, $recipient, $config, $args ) = @_;

  my $subject = $args->{subject};

  my $ticket = ref $recipient && $recipient->ticket;

  if ( $ticket ) {
    $subject = sprintf '[%s #%d] %s',
      $config->{subjecttag},
      $ticket,
      $subject,
    ;
  }

  return $subject;
}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

