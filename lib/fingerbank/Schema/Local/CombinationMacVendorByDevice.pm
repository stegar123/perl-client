package fingerbank::Schema::Local::CombinationMacVendorByDevice;

use Moose;
use namespace::autoclean;

extends 'fingerbank::Base::Schema::CombinationMacVendorByDevice';

__PACKAGE__->meta->make_immutable;

1;
