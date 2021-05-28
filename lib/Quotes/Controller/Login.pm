package Quotes::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub showlogin ($self) {

  $self->render(template => 'logon/logon');
}

sub login ($self) {

  if($self->authenticate->login_check($self->param('email'), $self->param('pass'), 'Basket')) {

    $self->session({ auth => 1 });
    return $self->redirect_to('/app/menu/show');
  }

  $self->redirect_to($self->config->{webserver});
  $self->flash('error' => 'Wrong login/password');
}
1;
