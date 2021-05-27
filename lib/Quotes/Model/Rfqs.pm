package Order::Model::Rfqs;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Data::Dumper;
use Order::Utils::Postgres::Columns;

has 'pg';

sub list_all_rfqs_from_status_p{
    my ($self, $supplier, $rfqstatus) = @_;

    $rfqstatus = 'NEW' unless $rfqstatus;

    my $stmt = qq{SELECT rfqs_pkey, rfq_no, rfqstatus, requestdate, regplate, note,
        userid as user, company, supplier
           FROM rfqs WHERE rfqstatus = ? AND supplier = ?};

    return $self->pg->db->query_p(
        $stmt, ($rfqstatus, $supplier)
    );
}

sub save_rfq_p{
    my ($self, $data) = @_;

    $data->{rfq_no} = $self->getRfqNo() unless $data->{rfq_no};

    return $self->pg->db->query_p(qq{
        INSERT INTO rfqs
            (rfq_no, rfqstatus, regplate, note, userid, company, supplier)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT (rfq_no)
            DO UPDATE SET moddatetime = now(), rfqstatus = ?, regplate = ?, note = ?, sent = ?
        RETURNING rfq_no
    },
        (
            $data->{rfq_no},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{userid},
            $data->{company},
            $data->{supplier},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{sent}
        )
    );
}

sub save_rfq{
    my ($self, $data) = @_;

    $data->{rfq_no} = $self->getRfqNo() unless $data->{rfq_no};

    my $rfq_no = $self->pg->db->query(qq{
        INSERT INTO rfqs
            (rfq_no, rfqstatus, regplate, note, userid, company, supplier)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT (rfq_no)
            DO UPDATE SET moddatetime = now(), rfqstatus = ?, regplate = ?, note = ?, sent = ?
        RETURNING rfq_no
    },
        (
            $data->{rfq_no},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{userid},
            $data->{company},
            $data->{supplier},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{sent}
        )
    )->hash->{rfq_no};

    return $rfq_no;
}
sub load_rfq_p{
    my ($self, $rfqs_pkey) = @_;

    return $self->pg->db->select_p(
        'rfqs',
        '*',
        {
            'rfqs_pkey' => $rfqs_pkey
        }
    );
}

sub load_from_rfqno{
    my ($self, $rfq_no) = @_;

    return $self->pg->db->select(
        'rfqs',
        '*',
        {
            'rfq_no' => $rfq_no
        }
    );
}


sub getRfqNo{
    my $self = shift;

    return try {
        $self->pg->db->query(qq{ SELECT nextval('rfqno') as rfq_no })->hash->{rfq_no};
    }catch{
        $self->capture_message("[Daje::Model::Rfqs::getRfqNo] " . $_);
        say $_;
    };
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Order::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'rfqs');

    return $data, $fields;
}

sub set_sent_at{
    my ($self, $data) = @_;

    return $self->pg->db->update(
        'rfqs',
        {
            sentat      => $data->{sentat},
            sent        => 'true',
            moddatetime => $data->{sentat},
            rfqstatus   => 'SENT',
        },
        {
            rfqs_pkey => $data->{rfq}->{rfqs_pkey}
        }
    );
}
1;