package Order::Controller::Wanted;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw{decode_json encode_json};
use Data::Dumper;

sub list_all_wanted_from_status_api{
    my $self = shift;

    $self->render_later;
    my $response;
    my $token = $self->req->headers->header('X-Token-Check');
    my $fields_list = $self->settings->get_settings_list('Wanted_grid_fields', $token);
    my $wantedstatus = $self->param('wantedstatus');
    say $wantedstatus;
    $self->user->get_company_fkey_from_token_p($token)->then(sub{
        my $collection = shift;

        my $company_pkey = $collection->hash->{companies_fkey};
        $self->wanted->list_all_wanted_from_status_p($company_pkey, $wantedstatus)->then(sub{
            my $result = shift;

            $response->{data} = $result->hashes->to_array;;
            $response->{responses} = $result->rows;
            $response->{headers} = $self->translations->grid_header('Wanted_grid_fields',$fields_list,'swe');

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

sub load_wanted_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    if($validator->required('wanted_pkey')){
        my $wanted_pkey = $self->param('wanted_pkey');
        if($wanted_pkey eq 'new') {$wanted_pkey = 0};

        $self->wanted->load_wanted_p($wanted_pkey)->then(sub{
            my $result = shift;

            my $field_list;
            my $rfq = $result->hash;
            $result->finish;
            ($rfq, $field_list) = $self->wanted->set_setdefault_data($rfq);

            my $detail = Daje::Utils::Translations->new(
                pg => $self->pg
            )->details_headers(
                'wanted', $field_list, $rfq, 'swe');

            $rfq->{header_data} = $detail;

            $self->render(json => $rfq);
        })->catch(sub {
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    }
}

sub create_wanted_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');
    $self->render_later;

    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{companies_fkey} and $data->{companies_fkey} > 0){
        $data->{companies_fkey} = $self->companies->load_loggedincompany($token)->{companies_pkey};
    }

    unless (exists $data->{supplier_fkey} and $data->{supplier_fkey} > 0){
        $data->{supplier_fkey} = $self->companies->load_loggedincompany($token)->{companies_pkey};
    }

    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }

    $data->{sent} = 'false' unless $data->{sent};
    $data->{wantedstatus} = 'NEW' unless $data->{wantedstatus};
    $data->{payload} = encode_json($data->{payload});

    $self->wanted->save_wanted_p($data)->then(sub{
        my $result = shift;

        $data->{wanted_pkey} = $result->hash->{wanted_pkey};
        $result->finish;

        $self->wanted->send_wanted_p($data)->then(sub{
            my $result = shift;


            $self->render(json => {result => 'Success'});
        })->catch(sub{
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    })->catch(sub{
        my $err = shift;

        $self->render(json => {error => $err});
    })->wait;
}

sub save_wanted_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');
    $self->render_later;

    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{companies_fkey} and $data->{companies_fkey} > 0){
        $data->{companies_fkey} = $self->companies->load_loggedincompany($token)->{companies_pkey};
    }

    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }
    $data->{sent} = 'false' unless $data->{sent};
    $data->{wantedstatus} = 'NEW' unless $data->{wantedstatus};

    $self->wanted->save_wanted_p($data)->then(sub{
        my $result = shift;

        $self->render(json => {result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {error => $err});
    })->wait;
}


sub send_wanted_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;

    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{companies_pkey}){
        $data->{companies_pkey} = $self->companies->load_loggedincompany(
            $token
        )->{companies_pkey};
    }

    unless (exists $data->{users_pkey}){
        $data->{users_pkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }

    $data->{sent} = 'true';
    $self->wanted->send_wanted_p($data)->then(sub{
        my $result = shift;

        $self->render(json => {result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {error => $err});
    })->wait;
}
1;


1;