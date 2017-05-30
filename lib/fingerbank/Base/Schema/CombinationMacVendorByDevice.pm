package fingerbank::Base::Schema::CombinationMacVendorByDevice;

use Moose;
use namespace::autoclean;

extends 'fingerbank::Base::Schema';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('combinationmacvendorbydevice');

__PACKAGE__->add_columns(
    "device_id",
);

__PACKAGE__->set_primary_key('device_id');

__PACKAGE__->result_source_instance->is_virtual(1);

# $1 = mac_vendor
#
__PACKAGE__->view_with_named_params(q{
    SELECT device_id FROM combination
    WHERE mac_vendor_id = $1
    GROUP BY device_id
    HAVING COUNT(device_id) > 5
    ORDER BY COUNT(device_id)
    DESC LIMIT 1
});

__PACKAGE__->meta->make_immutable;

1;
