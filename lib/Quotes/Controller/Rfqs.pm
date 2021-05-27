package Order::Controller::Rfqs;
use Mojo::Base 'Mojolicious::Controller';

use Scalar::Util qw(looks_like_number);
use Mojo::JSON qw{decode_json};
use Data::Dumper;

sub list_all_rfqs_from_status_supplier_api{
    my $self = shift;

    $self->render_later;
    my $response;
    my $fields_list = $self->settings->get_settings_list('Rfqs_grid_fields');
    my $rfqstatus = $self->param('rfqstatus');
    my $supplier= $self->param('supplier');

    $self->rfqs->list_all_rfqs_from_status_p($supplier, $rfqstatus)->then(sub{
        my $result = shift;

        $response->{data} = $result->hashes->to_array;;
        $response->{responses} = $result->rows;
        $response->{headers} = $self->translations->grid_header('Rfqs_grid_fields',$fields_list,'swe');

        $self->render(json => $response);
    })->catch(sub{
        my $err = shift;

        $response->{header_data} = '';
        $response->{error} = $err;
        say $err;
        $self->render(json => $response);
    })->wait;
}

sub list_all_rfqs_from_status_customer_api{
    my $self = shift;

    $self->render_later;
    my $response;
    my $fields_list = $self->settings->get_settings_list('Rfqs_grid_fields');
    my $rfqstatus = $self->param('rfqstatus');
    my $supplier= $self->param('supplier');

    $self->rfqs->list_all_rfqs_from_status_p($supplier, $rfqstatus)->then(sub{
        my $result = shift;

        $response->{data} = $result->hashes->to_array;;
        $response->{responses} = $result->rows;
        $response->{headers} = $self->translations->grid_header('Rfqs_grid_fields',$fields_list,'swe');

        $self->render(json => $response);
    })->catch(sub{
        my $err = shift;

        $response->{header_data} = '';
        $response->{error} = $err;
        say $err;
        $self->render(json => $response);
    })->wait;
}

sub load_rfq_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    if($validator->required('rfqs_pkey')){
        my $rfqs_pkey = $self->param('rfqs_pkey');
        if($rfqs_pkey eq 'new') {$rfqs_pkey = 0};

        $self->rfqs->load_rfq_p($rfqs_pkey)->then(sub{
            my $result = shift;

            my $field_list;
            my $rfq = $result->hash;
            $result->finish;
            ($rfq, $field_list) = $self->rfqs->set_setdefault_data($rfq);

            my $detail = $self->translations->details_headers(
                'rfqs', $field_list, $rfq, 'swe');

            $rfq->{header_data} = $detail;

            $self->render(json => $rfq);
        })->catch(sub {
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    }
}

sub save_rfq_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;
    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    $data->{sent} = 'false' unless $data->{sent};
    $data->{rfqstatus} = 'NEW' unless $data->{rfqstatus};

    $self->rfqs->save_rfq_p($data)->then(sub{
        my $result = shift;

        my $rfq_no = $result->hash->{rfq_no};
        $result->finish();
        $self->render(json => {rfq_no => $rfq_no, result => 'Success'});
    })->catch(sub{
        my $err = shift;

        say "[Order::Controller::Rfqs::save_rfq_api] " . $err;
        $self->render(json => {result => {error => $err} });
    })->wait;
}

sub send_rfq_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;

    my $body = $self->req->body;
    my $data = decode_json($body);
    say "send_rfq_api " . Dumper($data);
    delete $data->{header_data} if exists $data->{header_data};


    $data->{rfqstatus} = 'NEW' unless $data->{rfqstatus};
    $data->{sent} = 'true';
    my $result = $self->rfqs->send_rfq_message($data, $self->app->minion);

    if(looks_like_number($result)){
        $self->render(json => {rfq_no => $result, result => 'Success'});
    } else {
        $self->render(json => {rfq_no => 0, result => $result});
    }
}
1;
