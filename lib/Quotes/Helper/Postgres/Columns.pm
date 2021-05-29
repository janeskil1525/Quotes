package Quotes::Helper::Postgres::Columns;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

has 'pg';

sub set_setdefault_data ($self, $data, $table, $schema) {

    $schema = 'public' unless $schema;
    my $fieldsref = $self->get_table_column_names($table, $schema);

    my @fields = @$fieldsref;
    for my $i (0 .. $#fields)
    {
        $data->{$fields[$i]->{setting_value}} = ''
            unless exists $data->{$fields[$i]->{setting_value}};
    }

    return $data, $fieldsref;
}

sub get_table_column_names ($self, $table, $schema) {

    $schema = 'public' unless $schema;
    my $fields = $self->pg->db->query(
        qq{
        SELECT column_name as setting_value, 0 as setting_order
            FROM information_schema.columns
        WHERE table_schema = ?
            AND table_name = ?
        }, ($schema, $table)
    )->hashes->to_array;

    return $fields;
}
1;
