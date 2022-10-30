package Catalyst::Authentication::Credential::SaltedPasswords;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

use Scalar::Util        ();
use Catalyst::Exception ();
use Digest              ();

BEGIN {
    __PACKAGE__->mk_accessors(qw/_config realm/);
}

=head1 NAME

Catalyst::Authentication::Credential::SaltedPasswords - Authenticate a user
with DBIx::Class::SaltedPasswords

=head1 SYNOPSIS

    use Catalyst qw/
      Authentication
      /;

    package MyApp::Controller::Auth;

    sub login : Local {
        my ( $self, $c ) = @_;

        $c->authenticate({
            email => $c->req->param('username'),
            password => $c->req->param('password')
        });
    }

=head1 DESCRIPTION

This authentication credential checker takes authentication information
(most often a username) and a password, and attempts to validate the password
provided against the user retrieved from the store.

=head1 CONFIGURATION

    # example
    __PACKAGE__->config->{'Plugin::Authentication'} = 
                {  
                    default_realm => 'members',
                    realms => {
                        members => {
                            
                            credential => {
                                class => 'SaltedPasswords',
                                password_field => 'password',
                            },    
                            ...


=over 4 

=item class 

The classname used for Credential. This is part of
L<Catalyst::Plugin::Authentication> and is the method by which
Catalyst::Authentication::Credential::SaltedPasswords is loaded as the
credential validator. For this module to be used, this must be set to
'SaltedPasswords'.

=item password_field

The field in the user object that contains the password. This will vary
depending on the storage class used, but is most likely something like
'password'. In fact, this is so common that if this is left out of the config,
it defaults to 'password'. This field is obtained from the user object using
the get() method. Essentially: $user->get('passwordfieldname'); 
B<NOTE> If the password_field is something other than 'password', you must 
be sure to use that same field name when calling $c->authenticate(). 

=back

=head1 USAGE

The SaltedPasswords credential module is very simple to use. Once configured as
indicated above, authenticating using this module is simply a matter of
calling $c->authenticate() with an authinfo hashref that includes the
B<password> element. The password element should contain the password supplied
by the user to be authenticated, in clear text. The other information supplied
in the auth hash is ignored by the Password module, and simply passed to the
auth store to be used to retrieve the user. An example call follows:

    if ($c->authenticate({ username => $username,
                           password => $password} )) {
        # authentication successful
    } else {
        # authentication failed
    }

=head1 METHODS

There are no publicly exported routines in the Password module (or indeed in
most credential modules.)  However, below is a description of the routines 
required by L<Catalyst::Plugin::Authentication> for all credential modules.

=head2 new( $config, $app, $realm )

Instantiate a new SaltedPasswords object using the configuration hash provided
in $config. A reference to the application is provided as the second argument.
Note to credential module authors: new() is called during the application's
plugin setup phase, which is before the application specific controllers are
loaded. The practical upshot of this is that things like $c->model(...) will
not function as expected.

=cut

sub new {
    my ($class, $config, $app, $realm) = @_;
    
    my $self = { _config => $config };
    bless $self, $class;
    
    $self->realm($realm);
    
    $self->_config->{'password_field'} ||= 'password';
    return $self;
}

=head2 authenticate( $authinfo, $c )

Try to log a user in, receives a hashref containing authentication information
as the first argument, and the current context as the second.

=cut

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

   $c->log->debug('starting user authentication');

    ## because passwords may be in a hashed format, we have to make sure that we remove the 
    ## password_field before we pass it to the user routine, as some auth modules use 
    ## all data passed to them to find a matching user... 
    my $userfindauthinfo = {%{$authinfo}};
    delete($userfindauthinfo->{$self->_config->{'password_field'}});
    
    if ( my $user_obj = $realm->find_user($userfindauthinfo, $c) ) {
        my $password = $authinfo->{ $self->_config->{'password_field'} };
        if ( $user_obj->verify_password( $password ) ) {
            $c->log->info(sprintf 'sucessful login [%s]', $userfindauthinfo->{email});
            return $user_obj;
        } else {
            $c->log->warn(sprintf
                'failed login: u:%s | p:%s',
                $userfindauthinfo->{email},
                $password
            );
        }
    } else {
        my $msg = sprintf('unable to locate [%s]', $userfindauthinfo->{email});
        $c->log->info($msg);
        return;
    }
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;

