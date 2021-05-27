package quotes;
use Mojo::Base 'Mojolicious', -signatures;

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

  my $schema = from_json(Mojo::File->new(
      $self->dist_dir->child('schema/quotes.json')
  )->slurp) ;

  $self->pg->migrations->name('quotes')->from_file(
      $self->dist_dir->child('migrations/quotes.sql')
  )->migrate(0);

  $self->helper(menu => sub { state $menu = Quotes::Model::Menu->new(pg => shift->pg)});

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
}

1;
