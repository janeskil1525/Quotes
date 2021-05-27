package Order::Helper::Selectnames;
use Mojo::Base -base;

use Mojo::JSON qw{from_json};
use Data::Dumper;


sub get_select_names_json{
	my ($self, $json_field, $fields_list) = @_;

	my $selectnames = '';
	foreach (@{$fields_list}){
		my $properties;
		if($_->{setting_backend_properties}){
			$properties = from_json($_->{setting_backend_properties});
		}
		if(exists $properties->{special_selectname} ){
			if($properties->{special_selectname}){
				$selectnames .= " $properties->{special_selectname} as $_->{setting_value},";
			}
		}else{
			$selectnames .= " $json_field->>'$_->{setting_value}'::text as $_->{setting_value},";
		}
	}
	
	$selectnames = substr($selectnames, 0, -1);
	return $selectnames;
}

sub get_select_names{
	my ($self, $fields_list) = @_;
	
	my $selectnames = '';
	foreach (@{$fields_list}){
		$selectnames .= " $_->{setting_value},";
	}
	
	$selectnames = substr($selectnames, 0, -1);
	return $selectnames;
}

1;
