package Order::Controller::Quotes;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw{encode_json decode_json};

use Order::Model::Quotes;
use Data::Dumper;

sub load_quote_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    if($validator->required('quotes_pkey')){
        my $quotes_pkey = $self->param('quotes_pkey');
        if($quotes_pkey eq 'new') {$quotes_pkey = 0};

        $self->quotes->load_quote_p($quotes_pkey)->then(sub{
            my $result = shift;

            my $field_list;
            my $quote = $result->hash;
            $result->finish;
            ($quote, $field_list) = $self->quote->set_setdefault_data($quote);

            my $detail = $self->translations->new(
                pg => $self->pg
            )->details_headers(
                'quotes', $field_list, $quote, 'swe'
            );

            $quote->{header_data} = $detail;

            $self->render(json => $quote);
        })->catch(sub {
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    }
}

sub save_quote_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;
    my $body = $self->req->body;
    my $data;
    my $payload = decode_json($body);
    delete $payload->{header_data} if exists $payload->{header_data};


    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }

    if(exists $payload->{quote_no} and $payload->{quote_no} > 0){
        $data->{quote_no} = $payload->{quote_no};
    }else{
        $data->{quote_no} = 0;
    }

    $data->{sent} = 'false' unless $data->{sent};
    $data->{quotestatus} = 'NEW' unless $data->{quotestatus};
    $data->{payload} = $payload;
    $data->{supplier_fkey} = $payload->{supplier_fkey};
    $data->{companies_fkey} = $payload->{companies_fkey};


    $self->quotes->save_quote_p($data)->then(sub{
        my $result = shift;

        my $quote_no = $result->hash->{quote_no};
        $result->finish();
        $self->render(json => {quote_no => $quote_no, result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {result => {error => $err} });
    })->wait;
}

sub send_quote_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;

    my $body = $self->req->body;

    my $data;
    my $payload = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }

    $data->{quotestatus} = 'NEW' unless $data->{quotestatus};
    $data->{sent} = 'true';
    $data->{payload} = $payload;
    $data->{supplier_fkey} = $payload->{supplier_fkey};
    $data->{companies_fkey} = $payload->{companies_fkey};

    $self->quotes->send_quote_p($data)->then(sub{
        my $rfq_no = shift;

        $self->render(json => {quote_no => $rfq_no, result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {error => $err});
    })->wait;
}

sub list_all_quotes_from_status_api{
    my $self = shift;

    $self->render_later;
    my $response;
    my $token = $self->req->headers->header('X-Token-Check');
    my $fields_list = $self->settings->get_settings_list('Quotes_grid_fields', $token);
    my $quotestatus = $self->param('quotestatus');
    say $quotestatus;
    $self->user->get_company_fkey_from_token_p($token)->then(sub{
        my $collection = shift;

        my $company_pkey = $collection->hash->{companies_fkey};
        $self->quotes->list_all_quotes_from_status_p($company_pkey, $quotestatus)->then(sub{
            my $result = shift;

            $response->{data} = $result->hashes->to_array;;
            $response->{responses} = $result->rows;
            $response->{headers} = $self->translations->grid_header('Quotes_grid_fields',$fields_list,'swe');

            $self->render(json => $response);
        })->catch(sub{
            my $err = shift;

            $response->{header_data} = '';
            $response->{error} = $err;
            say $err;
            $self->render(json => $response);
        })->wait;

    })->catch(sub{
        my $err = shift;

        $response->{header_data} = '';
        $response->{error} = $err;
        say $err;
        $self->render(json => $response);
    })->wait;
}

1;


1;