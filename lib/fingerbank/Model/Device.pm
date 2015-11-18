package fingerbank::Model::Device;

=head1 NAME

fingerbank::Model::Device

=head1 DESCRIPTION

Handling 'Device' related stuff

=cut

use Moose;
use namespace::autoclean;

use fingerbank::Constant qw($TRUE $FALSE);
use fingerbank::Log;
use fingerbank::Util qw(is_error is_success);

extends 'fingerbank::Base::CRUD';

=head2 read

Override from L<fingerbank::Base::CRUD::read> because we want the device to be able to build his own parent on read time.

Defined '$with_parents' parameter will build parent, undef will simply return the device without parents.

=cut
sub read {
    my ( $self, $id, $with_parents ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my ($status, $return) = $self->SUPER::read($id);

    # There was an 'error' during the read
    return ($status, $return) if ( is_error($status) );

    # If parents are requested, we build them
    if ( (defined($with_parents) && $with_parents) && defined($return->{parent_id}) ) {
        $logger->debug("Device ID '$id' have at least 1 parent. Building parent(s) list");

        my $parent_id = $return->{parent_id};
        my $parent_exists = 1;  # We need to run at least once since we know parent(s) exists
        my @parents;            # Will keep the parent(s) attributes
        my @parents_ids;        # Will keep the ID(s) of parent(s) for easy access
        my $iteration = 0;      # Need to keep track of parent(s) in the parent(s) attributes array

        while ( $parent_exists ) {
            $logger->debug("Found parent ID '$parent_id' for device ID '$id'");
            push(@parents_ids, $parent_id);
            my $parent = $self->read($parent_id);
            foreach my $key ( keys %$parent ) {
                $parents[$iteration]{$key} = $parent->{$key};
            }
            $iteration ++;
            $parent_id = $parent->{parent_id} if ( defined($parent->{parent_id}) );
            $parent_exists = 0 if ( !defined($parent->{parent_id}) );
        }

        $return->{parents} = \@parents;
        $return->{parents_ids} = \@parents_ids;
    }

    return ( $fingerbank::Status::OK, $return );
}

=head2 is_a

=cut

sub is_a {
    my ( $self, $arg, $condition ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $status;

    # We need to convert a device type to an ID if needed
    my $device_id = $arg;
    if ( $arg !~ /^\d+$/ ) {
        my $query = {};
        $query->{'name'} = $arg;

        ( $status, my $query_result ) = $self->find([$query, { columns => ['id'] }]);
        return $FALSE if is_error($status);
    
        $device_id = $query_result->id;
    }

    # We first check if the requested device is matching the condition
    return $TRUE if ( $device_id eq $condition );

    # We want the device details including the parents
    ( $status, my $device ) = $self->read($device_id, 1);
    return $FALSE if is_error($status);

    my %parents_id = map { $_ => 1 } @{$device->{parents_ids}};

    if ( exists($parents_id{$condition}) ) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;
