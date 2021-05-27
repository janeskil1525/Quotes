package Order::Helper::Wanted::Interface;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::Wanted;
use Data::Dumper;

use Mojo::JSON qw{decode_json encode_json};



has 'pg';
has 'minion';

sub register {
    my ($self, $app) = @_;

    $self->pg($app->pg);

    $app->minion->add_task(send_wanted => \&_send_wanted);
    $self->minion($app->minion);


}

sub list_all_wanted_from_status_p{
    my ($self, $companies_fkey, $wantedstatus) = @_;

    return Order::Model::Wanted->new(
        pg => $self->pg
    )->list_all_wanted_from_status_p($companies_fkey, $wantedstatus);
}

sub load_wanted_p{
    my ($self, $wanted_pkey) = @_;

    return Order::Model::Wanted->new(
        pg => $self->pg
    )->load_wanted_p($wanted_pkey);
}

sub save_wanted_p{
    my($self, $data) = @_;

    return Order::Model::Wanted->new(
        pg => $self->pg
    )->save_wanted_p($data);
}

sub set_sent_at{
    my ($self, $data) = @_;

    return Order::Model::Wanted->new(
        pg => $self->pg
    )->set_sent_at($data);
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    return Order::Model::Wanted->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub send_wanted_p{
    my ($self, $data) = @_;

    my $wanted_p = Order::Model::Wanted->new(
        pg => $self->pg
    )->save_wanted_p($data);


    return Mojo::Promise->all($wanted_p )->then(sub{
        my ($wanted, $customer, $user, $supplier) = @_;

        my $wanted_no = $wanted->[0]->hash->{wanted_no};

        $wanted->[0]->finish();

        my $data->{wanted} = Daje::Model::Wanted->new(
            pg => $self->pg
        )->load_from_wantedno($wanted_no)->hash;

        $data->{wanted}->{payload} = decode_json($data->{wanted}->{payload});
        $data->{type} = 'wanted_sent';
        $data->{customer} = $customer->[0]->hash;
        $customer->[0]->finish();
        $data->{customer_user} = $user->[0]->hash;
        $user->[0]->finish();
        $data->{supplier} = $supplier->[0]->hash;
        $supplier->[0]->finish;

        my $json_result = encode_json($data);

        $self->minion->enqueue('send_wanted' => [$json_result] => {priority => 0});

        return $wanted_no;
    })->catch(sub{
        my $err = shift;

        say $err;
    });


}

sub _send_wanted{
    my($job, $import) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    my $data = decode_json $import;

    $year = "20$year";
    $data->{sentat} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year, $mon, $mday, $hour, $min, $sec);

    my $wanted_json = encode_json($data);
    $job->app->minion->enqueue('create_message' => [$wanted_json] );

    $job->app->wanted->set_sent_at($data);

    $job->finish({ status => "success"});

}


1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Wanted - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Wanted');

  # Mojolicious::Lite
  plugin 'Wanted';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Wanted> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Wanted> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut


1;