use strict;
use warnings;

package Catalyst::Plugin::Authorization::Roles::WaveRight;

use Set::Object         ();
use Scalar::Util        ();
use Catalyst::Exception ();

=head1 NAME

Catalyst::Plugin::Authorization::Roles::WaveRight - WaveRight specific role validation

=head1 DESCRIPTION

Checks that a user is in the given group

=head1 VARIABLES

=head2 $VERSION

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 has_roles

=cut

sub has_roles {
    my ( $c, @roles ) = @_;
    my $result = $c->check_user_roles(@roles);
    return $result->{granted} ? 1 : 0;
}

=head2 check_user_roles

=cut

sub check_user_roles {
    my ( $c, @roles ) = @_;
    local $@;
    my $result = eval { $c->assert_user_roles(@roles) };
    $result ||= {};
    $result->{error} ||= $@;
    return $result;
}

=head2 assert_user_roles

=cut

sub assert_user_roles {
    my ( $c, $user, @roles ) = @_;

    # if we werent passed a user get the logged in user
    if ( ! ref $user ) {
      unshift @roles, $user; # put first element back in to roles array
      $user = $c->user && $c->user->obj;
    }

    my $args = {};

    unless ( $user ) {
        $args->{error} = 'No logged in user';
    }

    unless ( @roles ) {
        $args->{error} = 'No roles specified';
    }

    local $" = ", ";

    my $index = $#roles;
    while ( $index > 0 ) {
        if ( ref $roles[ $index ] ) {
            my $permission         = $roles[ $index - 1 ];
            my $object             = splice @roles, $index, 1;
            $args->{ $permission } = $object;
            $index--;
        }
        $index--;
    }
    $args->{roles} = \ @roles;

    return $args if $args->{error};

    my @have = $user->roles($c, $args);
    my $need = Set::Object->new( @roles );

    $args->{have} = \ @have;

    if ( @have and $need->contains(@have) ) {
        $args->{granted} = 1;
    }

    return $args;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
