use strict;
use warnings;

package HTTP::Response;

sub json {
  my $self = shift;
  $self->_elem( '_json' => @_ );
}

package WWW::Mechanize;
# make a delete method so mechanize can DELETE
# cribbed from WWW/Mechanize.pm:put

sub delete {
    my $self = shift;
    my $uri = shift;

    $uri = $uri->url if ref($uri) eq 'WWW::Mechanize::Link';

    $uri = $self->base
            ? URI->new_abs( $uri, $self->base )
            : URI->new( $uri );

    # It appears we are returning a super-class method,
    # but it in turn calls the request() method here in Mechanize
    return $self->_SUPER_delete( $uri->as_string, @_ );
}


sub _SUPER_delete {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::DELETE( @parameters ), @suff );
}

sub patch {
    my $self = shift;
    my $uri = shift;

    $uri = $uri->url if ref($uri) eq 'WWW::Mechanize::Link';

    $uri = $self->base
            ? URI->new_abs( $uri, $self->base )
            : URI->new( $uri );

    # It appears we are returning a super-class method,
    # but it in turn calls the request() method here in Mechanize
    return $self->_SUPER_patch( $uri->as_string, @_ );
}


sub _SUPER_patch {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::PATCH( @parameters ), @suff );
}

package Test::WaveRight;
use base qw(Test::Class);
use Test::More;
use Catalyst::Test ();

use JSON::MaybeXS qw(JSON encode_json decode_json);
use Test::WWW::Mechanize::Catalyst;
use Test::MockDateTime;

use IPC::Run qw();

=head1 NAME

Test::WaveRight - WaveRight and WaveRightDB loader

=head1 DESCRIPTION

Base class for WaveRight tests

=head1 METHODS

=head2 startup

startup method is run once before all tests

=cut

sub startup : Test(startup => +1) {
  my($self, $app) = @_;

  $self->startup_self( $app );

  $self->startup_app;
}

=head2 startup_self

add data that is frequently used to the test object

=cut

sub startup_self {
  my( $self, $app ) = @_;

  $self->{app} = {
    name  => $app,
    model => {
      class => sprintf( '%sDB::', $app ),
      name  => sprintf( '%s::Model::%sDB::', $app, $app ),
    },
  };
}

=head2 startup_app

Stores a blank context in C<$self-E<gt>{c}> for easy access.

=cut

sub startup_app {
  my $self = shift;
  my $app  = $self->{app}{name};

  Catalyst::Test->import( $app );

  ( undef, $self->{c} ) = ctx_request('/');

  isa_ok(
    $self->{c} => $app => '$self->{c}'
  );
}

=head2 setup

create a fresh database for the test to operate in

=cut

sub setup : Tests(setup) {
  my $self = shift;

  # set up place for test database work to store data
  $self->{app}{database} = {
    name     => undef,
    commands => {
      setup    => [],
      teardown => [],
      dump     => [],
    }
  };

  if ( $self->database_per_test ) {
    $self->database_setup_commands;
    $self->database_populate_commands;
    $self->database_teardown_commands;
    $self->database_schema;
  }
}

=head2 ipc_runner

TODO:
die if no command
die if command looks weird(?)
die if call errors
report errors

=cut

sub ipc_runner {
  my $self = shift;
  my $command = shift;

  IPC::Run::run(
    $command,
    '>', \ my $out,
    '2>', \ my $err,
    IPC::Run::timeout( 10 )
  );
}

=head2 database_schema

creates and populates the database with mysql command line client

sets database config in DBIx::Class schema object

=cut

sub database_schema {
  my $self = shift;

  my $c        = $self->{c};
  my $commands = $self->{app}{database}{commands}{setup};

  foreach my $command ( @$commands ) {
    $self->ipc_runner( $command );
  }

  my $database = $self->{app}{database}{name};
  my $conf     = $self->database_test_config->{connection};

  my $dsn = sprintf $conf->{dsn}, $database;
  my $user = $conf->{user};
  my $pass = $conf->{pass};

#  diag("database: $database");
  my $schema = $c->model( $self->model )->schema;
  $schema->connection(  $dsn, $user, $pass, {}, $conf->{extra} );
}

=head2 test_database_config

=cut

sub database_test_config {
  my $self = shift;
  return $self->{c}->config->{DATABASE_TESTS};
}

=head2 database_per_test

=cut

sub database_per_test {
  my $self = shift;
  my $test_config = $self->database_test_config || {};
  return $test_config->{database_per_test};
}

=head2 database_setup_commands

=cut

sub database_setup_commands {
  my $self = shift;

  $self->database_create_commands;
  $self->database_deploy_commands;
  $self->database_dump_commands;
}

=head2 database_create_commands

=cut

use Silly::Werder;
sub database_create_commands {
  my $self = shift;

  my $database  = sprintf '%s_%s', lc $self->{app}{name}, Silly::Werder->get_werd;
  my $mysqlopts = $self->database_test_config->{mysqlopts};
  my $command   = [ mysqladmin => @$mysqlopts => create => $database ];

  # store the test db name in the test object
  $self->{app}{database}{name} = $database;

  # store the command to create the test db in the test object
  # so we can run it later
  my $commands = $self->{app}{database}{commands}{setup};
  push @$commands => $command;
}

=head2 database_deploy_commands

TODO - find .sql files in a dir for currently running test so there can be true
per test databases

=cut

sub database_deploy_commands {
  my $self = shift;

  my $c         = $self->{c}; # used for $c->path_to
  my $database  = $self->{app}{database}{name};
  my $commands  = $self->{app}{database}{commands}{setup};
  my $mysqlopts = $self->database_test_config->{mysqlopts};

  my @sql_files = $self->database_deploy_commands_sql_files;

  foreach my $file ( @sql_files ) {
    push @$commands => [
         mysql
      => @$mysqlopts
      => '-e'
      => sprintf('SOURCE %s', $c->path_to( $file ))
      => $database
    ];
  }
}

sub database_deploy_commands_sql_files {
  my $self = shift;

  my @files = qw( ../waveright/core/sql/init.sql ../sql/init.sql );

  return @files;
}

=head2 database_populate_commands

=cut

sub database_populate_commands {
  my $self = shift;

}

=head2 database_teardown_commands

=cut

sub database_teardown_commands {
  my $self = shift;

  my $database  = $self->{app}{database}{name};
  my $commands  = $self->{app}{database}{commands}{teardown};
  my $mysqlopts = $self->database_test_config->{mysqlopts};

  push @$commands => [
    mysqladmin
    => @$mysqlopts
    => '--force'
    => drop
    => $database
  ];
}

=head2 database_dump_commands

This just fills out $self->{app}{database}{dump}

call C<$self->database_dump('NAME')> to arbitarily dump the db during a test

for a test named 'SOME_TEST' in Test::MyAppDB::Result::MyResult invoked by
t/MyAppDB/Result/MyResult.t, it will put a mysqldump of the database in:

    MyApp/t/MyAppDB/Result/MyResult/YYYY-MM-DDTHH-MM-SS/SOME_TEST/NAME.sql

=cut

sub database_dump_commands {
  my $self = shift;
  my $c    = $self->{c};

  return unless $ENV{WR_DATABASE_DUMPS};

  my $database  = $self->{app}{database}{name};
  my $commands  = $self->{app}{database}{commands}{dump};
  my $mysqlopts = $self->database_test_config->{mysqlopts};

  my $now  = DateTime->now;
  my $date = $now->mdy('-') . 'T' . $now->hms('-');

  my $script_name = $0;
  $script_name =~ s|^.+?t/||;
  $script_name =~ s|\.t$||;

  my $current_method = $self->current_method;

  my $dir = sprintf 't/%s/%s/%s', $script_name, $date, $current_method;
  $dir    = $c->path_to($dir);
  File::Path::make_path( $dir ) or die "can't create output dir: $!";

  my $result_file = $dir . '/%s.sql';

  push @$commands => [
    mysqldump
    => @$mysqlopts
    => '--skip-opt'
    => '--no-create-info'
    => '--no-tablespaces'
    => '--dump-date=FALSE'
    => "--result-file=$result_file"
    => $database
  ];
}

=head2 database_dump

does a mysqldump of the database to:

    MyApp/t/MyAppDB/Result/MyResult/YYYY-MM-DDTHH-MM-SS/SOME_TEST/NAME.sql

=cut

sub database_dump {
  my($self, $filename) = @_;

  my $database  = $self->{app}{database}{name};
  my $template  = $self->{app}{database}{commands}{dump};
  my $mysqlopts = $self->database_test_config->{mysqlopts};

  return unless $template;

  my $commands = Clone::clone( $template );

  $commands->[-1][-2] = sprintf $commands->[-1][-2], $filename;

  foreach my $command ( @$commands ) {
    $self->ipc_runner( $command );
  }
}

=head2 model

=cut

sub model {
  my($self, $type, $table) = @_;

  if ( ! $type ) {
    my $schema_class = $self->{app}{model}{class};
    $schema_class    =~ s|\W+$||;
    return $schema_class;
  }

  return sprintf '%s%s', $self->{app}{model}{$type}, $table;
}

=head2 load_mech

=cut

sub load_mech {
  my $self = shift;

  # Load mechanize
  isa_ok(
    my $mech = $self->{mech} = Test::WWW::Mechanize::Catalyst->new(
      catalyst_app => $self->{app}{name}
    ) => 'Test::WWW::Mechanize::Catalyst' => '$self->{mech}'
  );

#  $mech->add_handler( request_send    => sub { diag(shift->dump) });
#  $mech->add_handler( response_done   => sub { diag(shift->dump) });

#  no reason to unconditionally set request content type, do it in POST
#  $mech->add_handler( request_prepare => sub {
#    my($request, $ua, $h) = @_;
#    $request->content_type('application/json');
#  });

  return $mech;
}

=head2 expected_login_response

=cut

sub expected_login_response {
  my $self = shift;
  my $c    = $self->{c};

  my $expected = {
    ok => JSON->true,
  
    password => {
      new     => undef,
      current => undef,
      match   => undef
    },
  
    user => {
      name     => $c->config->{SYSTEM_USER}{name},
      loggedIn => JSON->true
    },
  
    toaster => {
      title           => 'Log In Success',
      timeout         => 7500,
      body            => 'You are now logged in and can manage dashboards.',
      type            => 'success',
      showCloseButton => JSON->true
    },
  };

  return $expected;
}

=head2 log_in

=cut

sub log_in {
  my( $self, $credentials ) = @_;
  my $c    = $self->{c};
  my $mech = $self->{mech};

  # get credentials from config if they weren't passed
  $credentials ||= $c->config->{SYSTEM_USER}{credentials};

  my $response = $self->post( '/api/account/login' => $credentials );

  diag explain $response->json if $ENV{DIAG};

  my $expect = $self->expected_login_response( $credentials );
  my $got    = Clone::clone( $response->json );

  # delete all keys from $got that are not in $expect so we don't have to
  # maintain gigantic init hashes just to verify login
  foreach my $got_key ( keys %$got ) {
    if ( ! grep $got_key eq $_, keys %$expect ) {
      delete $got->{ $got_key };
    }
  }
  is_deeply( $got, $expect, 'login complete' );

  return $response;
}


=head2 log_out

=cut

sub log_out {
  my( $self ) = @_;
  my $c    = $self->{c};
  my $mech = $self->{mech} || $self->load_mech;

  my $response = $self->post( '/api/account/logout' );

#  is_deeply( $response->json, $expected_logout_response, 'logout complete' );

  return $response;
}

=head2 shutdown

this deletes this test's database

can delete left over databases with:

    bin/database/drop-test-dbs
    mysql -uangulysttest --password='...' --batch -e 'SHOW DATABASES' | grep ^angulyst_ | xargs -I{} mysqladmin -uangulysttest --password='...' --force drop {}

=cut

sub teardown : Tests(teardown) {
  my $self = shift;

  my $commands = $self->{app}{database}{commands}{teardown};

  foreach my $command ( @$commands ) {
    $self->ipc_runner( $command );
  }
}

=head2 shutdown

Explicitly undefines the context created in the startup method.

=cut

# shutdown methods are run once after tests.
sub shutdown : Tests(shutdown) {
  my $self = shift;
  $self->{c} = undef;
}

=head2 get

tricky - in the test methods calling $self->get called in to Catalyst::Test's
get request - so override it. Guess we'll never need it?

=cut

sub mech_get {
  my( $self, $url ) = @_;
  my $mech = $self->{mech};

  my $callback = sub {
    my($www, $endpoint) = @_;
    $www->get( $endpoint );
  };

  my $response = Test::MockDateTime::on(
    "2017-01-28 20:30:00" => 'America/Los_Angeles'
      =>
    $callback, $mech, $url
  );

  if ($response->is_success) {
    my $json = decode_json( $response->decoded_content );
    $response->json( $json );
  }

  return $response;
}

=head2 post

=cut

sub post {
  my( $self, $url, $json ) = @_;
  my $mech = $self->{mech};

  my $callback = sub {
    my($www, $endpoint, $data) = @_;

    my $post_data = $data;
    if ( ref $data ne 'ARRAY' ) {
      $post_data = [
        'Content-Type' => 'application/json; charset=UTF-8',
        Content        => $data && encode_json $data
      ];
    }

    $www->post( $endpoint => @$post_data )
  };

  my $response = Test::MockDateTime::on(
    "2017-01-28 20:30:00" => 'America/Los_Angeles'
      =>
    $callback, $mech, $url, $json
  );

  if ($response->is_success) {
    my $json = decode_json( $response->decoded_content );
    $response->json( $json );
  }

  return $response;
}

=head2 delete

make a HTTP DELETE request for the resource

=cut

sub delete {
  my( $self, $url  ) = @_;
  my $mech = $self->{mech};

  my $callback = sub {
    my($www, $endpoint, $data) = @_;
    $www->delete( $endpoint )
  };

  my $response = Test::MockDateTime::on(
    "2017-01-28 20:30:00" => 'America/Los_Angeles'
      =>
    $callback, $mech, $url
  );

  if ($response->is_success) {
    my $json = decode_json( $response->decoded_content );
    $response->json( $json );
  }

  return $response;
}

=head2 patch

=cut

sub patch {
  my( $self, $url, $json ) = @_;
  my $mech = $self->{mech};

  my $callback = sub {
    my($www, $endpoint, $data) = @_;
    $www->patch( $endpoint => Content => $data && encode_json $data )
  };

  my $response = Test::MockDateTime::on(
    "2017-01-28 20:30:00" => 'America/Los_Angeles'
      =>
    $callback, $mech, $url, $json
  );

  if ($response->is_success) {
    my $json = decode_json( $response->decoded_content );
    $response->json( $json );
  }

  return $response;
}

=head1 AUTHOR

WaveRight Information Technology, LLC.

=head1 LICENSE

WaveRight License

=cut

1;
