package Order::Model::Quotes;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw{to_json};
use Try::Tiny;
use Data::Dumper;

has 'pg';

sub list_all_quotes_from_status_p{
    my ($self, $companies_fkey, $quotestatus) = @_;

    $quotestatus = 'NEW' unless $quotestatus;

    return $self->pg->db->query_p(
        qq{SELECT quotes_pkey, quote_no, quotestatus, quotedate,
         (SELECT userid || ' ' || username FROM users WHERE users_pkey = users_fkey) as user,
          (SELECT name FROM companies WHERE companies_pkey = companies_fkey) as customer,
           (SELECT name FROM companies WHERE companies_pkey = supplier_fkey) as supplier
           FROM quotes WHERE quotestatus = ? AND companies_fkey = ?},
        ($quotestatus, $companies_fkey)
    );
}

sub save_quote_p{
    my ($self, $data) = @_;

    $data->{quote_no} = $self->getQuoteNo() unless $data->{quote_no};
    $data->{quotedate} = $self->getQuoteDate() unless $data->{quotedate};
    $data->{payload} = to_json($data->{payload});

    return $self->pg->db->query_p(qq{
        INSERT INTO quotes
            (quote_no, quotestatus, quotedate, payload, users_fkey, companies_fkey, supplier_fkey)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT (quote_no)
            DO UPDATE SET moddatetime = now(), quotestatus = ?, payload = ?,  sent = ?
        RETURNING quote_no
    },
        (
            $data->{quote_no},
            $data->{quotestatus},
            $data->{quotedate},
            $data->{payload},
            $data->{users_fkey},
            $data->{companies_fkey},
            $data->{supplier_fkey},
            $data->{quotestatus},
            $data->{payload},
            $data->{sent}
        )
    );
}

sub load_quote_p{
    my ($self, $rfqs_pkey) = @_;

    return $self->pg->db->select_p(
        'quotes',
        '*',
        {
            'quotes_pkey' => $rfqs_pkey
        }
    );
}

sub load_from_quoteno{
    my ($self, $quote_no) = @_;

    return $self->pg->db->select(
        'quotes',
        '*',
        {
            'quote_no' => $quote_no
        }
    );
}


sub getQuoteNo{
    my $self = shift;

    return try {
        $self->pg->db->query(qq{ SELECT nextval('quote_no') as quote_no })->hash->{quote_no};
    }catch{
        $self->capture_message("[Daje::Model::Quotes::getQuoteNo] " . $_);
        say $_;
    };
}

sub getQuoteDate{
    my $self = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    $year = "20$year";
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year, $mon, $mday, $hour, $min, $sec);
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'quotes');

    return $data, $fields;
}

sub set_sent_at{
    my ($self, $data) = @_;

    return $self->pg->db->update(
        'quotes',
        {
            sentat => $data->{sentat},
            sent   => 'true',
        },
        {
            quotes_pkey => $data->{quotes_pkey}
        }
    );
}

1;


1;