package quotes;
use Mojo::Base 'Mojolicious', -signatures;

use Authenticate::Helper::Client;
use Translations::Helper::Client;
use Parameters::Helper::Client;

use Mojo::Pg;

use File::Share;
use Mojo::File;
use Mojo::JSON qw {from_json};

$ENV{TRANSLATIONS_HOME} = '/home/jan/Project/Translations/'
    unless $ENV{TRANSLATIONS_HOME};

has dist_dir => sub {
  return Mojo::File->new(
      File::Share::dist_dir('Translations')
  );
};

has home => sub {
  Mojo::Home->new($ENV{TRANSLATIONS_HOME});
};

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  mmy $config = $self->plugin('Config');

  $self->helper(pg => sub {state $pg = Mojo::Pg->new->dsn(shift->config('pg'))});
  $self->log->path($self->home() . $self->config('log'));

  $self->renderer->paths([
      $self->dist_dir->child('templates'),
  ]);
  $self->static->paths([
      $self->dist_dir->child('public'),
  ]);

  # my $schema = from_json(Mojo::File->new(
  #     $self->dist_dir->child('schema/quotes.json')
  # )->slurp) ;


  $self->pg->migrations->name('quotes')->from_file(
      $self->dist_dir->child('migrations/quotes.sql')
  )->migrate(0);

  $self->helper(menu => sub { state $menu = Quotes::Model::Menu->new(pg => shift->pg)});
  $self->helper(authenticate => sub {
    state $authenticate = Authenticate::Helper::Client->new(pg => shift->pg)}
  );
  $self->authenticate->endpoint_address($self->config->{authenticate}->{endpoint_address});
  $self->authenticate->key($self->config->{authenticate}->{key});

    $self->helper(
        rfqs => sub {
            state $rfqs= Order::Helper::Rfqs->new(pg => shift->pg)
        }
    );
    $self->rfqs($self->minion);

    $self->helper(
        wanted => sub {
            state $wanted = Order::Helper::Wanted::Interface->new(pg => shift->pg)
        }
    );

  $self->helper(
      translations => sub {
        state $translations = Translations::Helper::Client->new();
      }
  );
  $self->translations->endpoint_address($self->config->{translations}->{endpoint_address});
  $self->translations->key($self->config->{translations}->{key});

  $self->helper(
      settings => sub {
        state $settings = Parameters::Helper::Client->new(pg => shift->pg)
      }
  );
  $self->settings->endpoint_address($self->config->{parameters}->{endpoint_address});
  $self->settings->key($self->config->{parameters}->{key});

  # Configure the application
  $self->secrets($config->{secrets});

  $self->plugin(
      OpenAPI => {
          spec     => $self->dist_dir->child('openapi') . '/quotes.json',
          security => {
              apiKey => sub {
                my ($c, $definition, $scopes, $cb) = @_;
                return $c->$cb() if $c->tx->req->content->headers->header('X-Token-Check') eq $c->config->{key};
                return $c->$cb() if $c->authenticate->authenticate(
                    $c->req->headers->header('X-User-Check'), $c->req->headers->header('X-Token-Check')
                );
                return $c->$cb('Api Key not valid');
              }
          }
      }
  );
  # Router
  my $r = $self->routes;
  my $api_route = $r->under('/api' => sub {
    my $c = shift;
    #say "authentichate " . $c->req->headers->header('X-Token-Check');
    # Authenticated
    return 1 if $c->req->headers->header('X-Token-Check') eq $c->config->{key} ;
    return 1 if $c->authenticate->authenticate(
        $c->req->headers->header('X-User-Check'), $c->req->headers->header('X-Token-Check')
    );
    # Not authenticated
    $c->render(json => '{"error":"unknown error"}');
    return undef;
  });

  my $auth_route = $r->under( '/app', sub {
    my ( $c ) = @_;

    return 1 if ($c->session('auth') // '') eq '1';
    $c->redirect_to('/');
    return undef;
  } );
  # Normal route to controller
  $r->get('/')->to('login#showlogin');
  $r->post('/login')->to('login#login');
  $auth_route->get('/menu/show')->to('menu#showmenu');

}

1;
