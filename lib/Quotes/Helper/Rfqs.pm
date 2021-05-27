package Order::Helper::Rfqs;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::Rfqs;
use Daje::Utils::Sentinelsender;

use Mojo::JSON qw{decode_json encode_json};
use Mojo::Promise;
use Data::Dumper;
use Try::Tiny;

has 'pg';
has 'minion';

sub list_all_rfqs_from_status_p{
    my ($self, $companies_fkey, $rfqstatus) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->list_all_rfqs_from_status_p($companies_fkey, $rfqstatus);
}

sub load_rfq_p{
    my ($self, $rfqs_pkey) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->load_rfq_p($rfqs_pkey);
}

sub save_rfq_p{
    my ($self, $data) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->save_rfq_p($data);
}

sub send_rfq_message {
    my ($self, $data, $minion) = @_;

    my $result = try {
        my $rfq_no = Order::Model::Rfqs->new(
            pg => $self->pg
        )->save_rfq($data);

        say "rfq_no " . $rfq_no;
        my $message->{payload} = Order::Model::Rfqs->new(
            pg => $self->pg
        )->load_from_rfqno($rfq_no)->hash;

        $message->{payload}->{type} = 'rfq_sent';
        $message->{company} = $data->{supplier};
        $message->{companies_fkey} = $data->{companies_fkey};
        $minion->enqueue('send_message' => [ $message ] => { priority => 0 });

        $message->{company} = $data->{company};
        $message->{companies_fkey} = $data->{supplierfkey};
        $message->{payload}->{type} = 'rfq_received';
        $minion->enqueue('send_message' => [ $message ] => { priority => 0 });

        Order::Model::Rfqs->new(
            pg => $self->pg
        )->set_sent_at($data);

        return 'Success';
    } catch {
        say $_;
        $self->capture_message(
            '', 'Order::Helper::Rfqs::send_rfq_message', 'send_rfq_message', (caller(0))[3], $_
        );
        return $_;
    };

    return $result;
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Rfqs - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Rfqs');

  # Mojolicious::Lite
  plugin 'Rfqs';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Rfqs> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Rfqs> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut


1;