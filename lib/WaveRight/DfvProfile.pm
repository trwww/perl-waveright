use warnings;
use strict;

use Data::Dumper;
use Data::FormValidator::Multi; # load now so controllers don't have to

package WaveRight::Data::FormValidator::Profile;
use base qw(Data::FormValidator::Profile);

sub add {
  my ($self, $field, %args) = @_;

  $self->SUPER::add( $field, %args );

  # the dfv profile
  my $profile = $self->profile;

  if ( $args{inflate} ) {
    $profile->{untaint_constraint_fields} = [
      Data::FormValidator::Results::_arrayify(
        $profile->{untaint_constraint_fields}
      ),
      $field,
    ];
  }

  return $self;
}

package WaveRight::DfvProfile;
use Data::FormValidator::Constraints qw(match_email FV_max_length);
use Regexp::Common;

#  warn Data::Dumper->Dump([ $profile_builder_args ], [ qw(parsed_args) ]);
sub get {
  my $class = shift;

  my $profile_builder_args = get_profile_builder_args( $class );

  my $builder = $profile_builder_args->{builder};
  my $method  = $profile_builder_args->{method};
  my $app     = $profile_builder_args->{app};
  my $model   = $profile_builder_args->{model};

  my $builder_instance = $builder->instantiator( app => $app, model => $model);

  # builds the profile for the action
  $builder_instance->$method( @_ );

  my $profile = $builder_instance->get_profile;

  return $profile;
}

sub get_profile_builder_args {
  my $injected_class_name = shift;

  (my $app = $injected_class_name) =~ s|:.+||;

  my $subroutine = (caller(2))[3];

  (my $builder_subclass = $subroutine) =~ s|.+Controller::(.+)::.+|$1|;
  (my $method = $subroutine) =~ s|.+::||;

  return {
    app     => $app,
    model   => $app . 'DB',
    builder => $app . '::DfvProfile::' . $builder_subclass,
    method  => $method,
  };
}

# this is just a constructor, but giving it an obscure name
sub instantiator {
  my($class, %data) = @_;
  my $self = bless { %data }, $class;

  my $builder = $self->data_formvalidator_profile_skeleton;

  $self->{builder} = $builder;

  return $self;
}

sub data_formvalidator_profile_skeleton {
  my $self = shift;

  my $dfvp = WaveRight::Data::FormValidator::Profile->new({
    filters => [qw( trim )],
    msgs    => {
      invalid_seperator => ' ## ',
      format            => 'ERROR: %s',
      missing           => 'FIELD IS REQUIRED',
      invalid           => 'FIELD IS INVALID',
      constraints       => {
      }
    },
  });

  return $dfvp;
}

sub get_profile {
  my $self = shift;

  my $builder = $self->{builder};
  my $profile = $builder->profile;

  return $profile;
}

sub _optional {
  my $self    = shift;
  my $field   = shift;
  my $builder = $self->{builder};

  $builder->add($field,
    required => 0,
  );
}

sub login_email {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('email',
    required    => 1,
    constraints => [
      {
        name              => 'email_address_invalid',
        constraint_method => sub {
          my ($dfv, $val) = @_;
          return match_email($val),
        }
      },
      {
        name              => 'email_address_noexists',
        constraint_method => sub {
          my ($dfv, $val) = @_;
          return !! $app->model($model . '::Persons')->search({email => $val})->first;
        },
      },
    ],
    msgs => {
      email_address_invalid  => 'NOT A VALID EMAIL ADDRESS',
      email_address_noexists => 'NO USER BY THIS ADDRESS',
    },
  );
}

sub login_pass {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('pass',
    required    => 1,
    constraints => [
      {
        name              => 'wrong_password',
        params            => [ 'email', 'pass' ],
        constraint_method => sub {
          my ($dfv, $email, $pass) = @_;

          my $u = $app->model($model . '::Persons')->search({
            email => $email
          })->first;

          if ( $u ) {
            return $u->verify_password( $pass );
          } else {
            return 0;
          }
        },
      },
    ],
    msgs => {
      wrong_password => 'INCORRECT PASSWORD',
    },
  );
}

sub remember {
  my $self    = shift;
  my $builder = $self->{builder};

  $builder->add('remember',
    required => 0,
  );
}

sub person_name {
  my $self    = shift;
  my $builder = $self->{builder};

  $builder->add('name',
    required => 1,
  );
}

sub group_order {
  my $self    = shift;
  my $builder = $self->{builder};

  $builder->add('order',
    required    => 1,
    constraints => [
      {
        name              => 'order_out_of_range',
        constraint_method => sub {
          my ($dfv, $val) = @_;
          return unless $val =~ /$RE{num}{real}/;
          return( ( $val < 256 ) and ( $val > 0 ) );
        }
      },
    ],
    msgs => {
      order_out_of_range => 'MUST BE < 256 AND > 0',
    },
  );
}

sub signup_email {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('email',
    required    => 1,
    constraints => [
      {
        name              => 'email_address_invalid',
        constraint_method => sub {
          my ($dfv, $val) = @_;
          return match_email($val),
        }
      },
      {
        name              => 'email_address_exists',
        constraint_method => sub {
          my ($dfv, $val) = @_;
          return ! $app->model($model . '::Persons')->search({email => $val})->first;
        },
      },
    ],
    msgs => {
      email_address_invalid => 'NOT A VALID EMAIL ADDRESS',
      email_address_exists  => 'EMAIL ADDRESS ALREADY REGISTERED',
    },
  );
}

sub signup_pass {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('pass',
    required    => 1,
    constraints => [
      {
        name              => 'six_char_minimum',
        constraint_method => sub {
            my ($dfv, $val) = @_;
            return length($val) >= 6,
        }
      },
      {
        name              => 'has_a_number',
        constraint_method => sub {
            my ($dfv, $val) = @_;
            return $val =~ m|\d|,
        }
      },
      {
        name              => 'has_lowercase_letter',
        constraint_method => sub {
            my ($dfv, $val) = @_;
            return $val =~ m|[a-z]|,
        }
      },
#	  {
#	    name              => 'has_capital_letter',
#	    constraint_method => sub {
#	        my ($dfv, $val) = @_;
#	        return $val =~ m|[A-Z]|,
#	    }
#	  },
      {
        name              => 'is_not_email',
        params            => [ 'pass', 'email' ],
        constraint_method => sub {
          my ($dfv, $pass, $email) = @_;
            return $pass ne $email,
        }
      },
    ],
    msgs => {
      six_char_minimum     => 'SIX CHAR MINIMUM ON PASSWORD LENGTH',
      has_a_number         => 'MUST HAVE A NUMBER [0 - 9]',
      has_lowercase_letter => 'MUST HAVE LOWERCASE LETTER [a - z]',
      has_capital_letter   => 'MUST HAVE CAPITAL LETTER [A - Z]',
      is_not_email         => 'CANNOT USE EMAIL AS PASSWORD',
    },
  );
}

sub signup_pass_match {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('pass_match',
    required    => 1,
    constraints => [
      {
        name              => 'both_match',
        params            => [ 'pass_match', 'pass' ],
        constraint_method => sub {
          my ($dfv, $match, $pass) = @_;
            return $pass eq $match;
        }
      },
    ],
    msgs => {
      both_match => 'PASSWORD RETYPED INCORRECTLY',
    },
  );
}

sub signup_pass_hint {
  my $self    = shift;
  my $builder = $self->{builder};
  my $app     = $self->{app};
  my $model   = $self->{model};

  $builder->add('pass_hint',
    required    => 0,
    constraints => [
      {
        name              => 'is_not_hint',
        params            => [ 'pass', 'pass_hint' ],
        constraint_method => sub {
          my ($dfv, $pass, $hint) = @_;
#            return adist($pass, $hint) > 1;
          return ($pass && $hint) && ( lc($pass) ne lc($hint) );
        }
      },
    ],
    msgs => {
      is_not_hint => 'HINT IS TOO SIMILAR TO PASSWORD',
    },
  );
}

1;
