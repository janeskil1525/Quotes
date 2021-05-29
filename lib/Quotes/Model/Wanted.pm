package Quotes::Model::Wanted;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Quotes::Helper::Postgres::Columns;

has 'pg';

sub list_all_wanted_from_status_p{
    my ($self, $companies_fkey, $wantedstatus) = @_;

    $wantedstatus = 'NEW' unless $wantedstatus;

    return $self->pg->db->query_p(
        qq{SELECT wanted_pkey, wanted_no, wantedstatus, wanteddate, payload, note,
         (SELECT userid || ' ' || username FROM users WHERE users_pkey = users_fkey) as user,
          (SELECT name FROM companies WHERE companies_pkey = companies_fkey) as customer,
           (SELECT name FROM companies WHERE companies_pkey = supplier_fkey) as supplier
           FROM rfqs WHERE wantedstatus = ? AND companies_fkey = ?},
        ($wantedstatus, $companies_fkey)
    );
}

sub save_wanted_p{
    my($self, $data) = @_;

    $data->{wanted_no} = $self->getWantedNo() unless $data->{wanted_no};

    return $self->pg->db->query_p(
        qq{
            INSERT INTO wanted
                (wanted_no, wantedstatus, payload, users_fkey, companies_fkey, supplier_fkey)
            VALUES (?,?,?,?,?,?)
            ON CONFLICT (wanted_no)
            DO UPDATE SET moddatetime = now(), wantedstatus = ?, sent = ?
            RETURNING wanted_no
         },
        (
            $data->{wanted_no},
            $data->{wantedstatus},
            $data->{payload},
            $data->{users_fkey},
            $data->{companies_fkey},
            $data->{supplier_fkey},
            $data->{wantedstatus},
            $data->{sent}
        )
    );
}

sub load_from_wantedno{
    my ($self, $wanted_no) = @_;

    return $self->pg->db->select(
        'wanted',
        '*',
        {
            'wanted_no' => $wanted_no
        }
    );
}

sub load_wanted_p{
    my ($self, $wanted_pkey) = @_;

    return $self->pg->db->select_p(
        'wanted',
        '*',
        {
            'wanted_pkey' => $wanted_pkey
        }
    );
}

sub set_sent_at{
    my ($self, $data) = @_;

    my $result = try {
        $self->pg->db->update(
            'wanted',
            {
                sentat => $data->{sentat},
                sent   => 'true',
            },
            {
                wanted_pkey => $data->{wanted_pkey}
            }
        );
    }catch{
        $self->capture_message("[Daje::Model::Wanted::getWantedNo] " . $_);
        say $_;
    };
    return $result;
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Quotes::Helper::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'wanted');

    return $data, $fields;
}


sub getWantedNo{
    my $self = shift;

    return try {
        $self->pg->db->query(qq{ SELECT nextval('wantedno') as wanted_no })->hash->{wanted_no};
    }catch{
        $self->capture_message("[Daje::Model::Wanted::getWantedNo] " . $_);
        say $_;
    };
}
1;

1;