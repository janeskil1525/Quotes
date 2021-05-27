package Order::Helper::Quotes;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Daje::Model::Quotes;
use Daje::Model::Companies;
use Daje::Model::User;

use Mojo::JSON qw {decode_json encode_json from_json};

our $VERSION = '0.01';

has 'pg';
has 'minion';

sub register {
    my ($self, $app) = @_;

    $self->pg($app->pg);
    $self->minion($app->minion);
    $app->minion->add_task(send_quote => \&_send_quote);
    $app->helper(quotes => sub {$self});

}

sub _send_quote{
    my($job, $import) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    my $data = decode_json $import;
    $year = "20$year";
    $data->{sentat} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year, $mon, $mday, $hour, $min, $sec);
    $data->{messagetype} = 'quote_sent';

    my $quote_json = encode_json($data);
    $job->app->minion->enqueue('create_message' => [$quote_json] );

    $job->app->quotes->set_sent_at($data);

    $job->finish({status => "success"});
}

sub list_all_quotes_from_status_p{
    my ($self, $companies_fkey, $quotestatus) = @_;

    return Daje::Model::Quotes->new(
        pg => $self->pg
    )->list_all_quotes_from_status_p($companies_fkey, $quotestatus);
}

sub save_quote_p{
    my ($self, $data) = @_;

    return Daje::Model::Quotes->new(
        pg => $self->pg
    )->save_quote_p($data);
}

sub load_quote_p{
    my ($self, $quotes_pkey) = @_;

    return Daje::Model::Quotes->new(
        pg => $self->pg
    )->load_quote_p($quotes_pkey);
}

sub set_sent_at{
    my ($self, $data) = @_;

    return Daje::Model::Quotes->new(
        pg => $self->pg
    )->set_sent_at($data);
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    return Daje::Model::Quotes->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub send_quote_p{
    my ($self, $data) = @_;


    my $quote_p = Daje::Model::Quotes->new(
        pg => $self->pg
    )->save_quote_p($data);

    my $user_p =  Daje::Model::User->new(
        pg => $self->pg
    )->load_user_p(
        $data->{users_fkey}
    );

    return Mojo::Promise->all($quote_p, $user_p)->then(sub{
        my ($quote, $user) = @_;

        my $quote_no = $quote->[0]->hash->{quote_no};

        $quote->[0]->finish();

        my $data->{quote} = Daje::Model::Quotes->new(
            pg => $self->pg
        )->load_from_quoteno($quote_no)->hash;

        $data->{quote}->{payload} = from_json($data->{quote}->{payload});
        $data->{type} = 'quote_sent';

        $data->{supplier_user} = $user->[0]->hash;
        $user->[0]->finish();

        my $json_result = encode_json($data);

        $self->minion->enqueue('send_quote' => [$json_result] => {priority => 0});

        return $quote_no;
    })->catch(sub{
        my $err = shift;

        say $err;
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Quotes - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Quotes');

  # Mojolicious::Lite
  plugin 'Quotes';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Quotes> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Quotes> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut


1;