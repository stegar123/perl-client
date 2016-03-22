package fingerbank::Source::RedisDB;

=head1 NAME

fingerbank::Source::RedisDB

=head1 DESCRIPTION

Source for RedisDB combination matching

=cut

use Moose;
extends 'fingerbank::Base::Source';

use strict;
use warnings;

use fingerbank::DB;
use fingerbank::Redis;
use fingerbank::Constant qw($TRUE $FALSE $DEFAULT_SCORE);
use fingerbank::Status;
use fingerbank::Util qw(is_error is_success is_enabled);
use fingerbank::Model::Device;
use fingerbank::Model::Combination;
use Data::PowerSet qw(powerset);
use Time::HiRes qw(time);

=head2 match

Check whether or not the arguments match this source

=cut

sub match {
    my ($self, $args, $other_results) = @_;

    my $start = time;

    my $logger = fingerbank::Log::get_logger;

    my $redis = fingerbank::Redis->new;
    my $connection = $redis->connection;
            
    # searching for the perfect match with the empty values
    my @sets = map{$_."-".$args->{$_}} keys(%$args);
    my @sets_without_empty = map{ $args->{$_} ? $_."-".$args->{$_} : ()} keys(%$args);
    my @found = $connection->sinter(@sets);

    if(@found){
        $logger->info("Found perfect match ! : ".$found[0]);
        my $combination = fingerbank::Model::Combination->read($found[0]);
        my (@infos) = $self->_buildResult($combination->{device_id});
        $logger->trace(sub { "RedisDB took : ".(time-$start) });
        return @infos;
    }

    if(fingerbank::Config::configured_for_api){
        $logger->debug("Not matching redis sub-sets as API is configured, thus only an exact match is useful here.");
        return ($fingerbank::Status::NOT_FOUND)
    }

    my $i = scalar(@sets_without_empty);
    # While we can split our set into smaller subsets
    while($i > 0){
        # we split our set in all possible subsets of length $i
        # order is not considered in subsets
        # ex : [1,2,3] = [1,2], [2,3], ...
        my $subsets = powerset({min => $i, max => $i}, @sets_without_empty);
        my %found;
        foreach my $subset (@$subsets){
            my @intersections = $connection->sinter(@$subset);
            if(@intersections){
                $found{join(',',@$subset)} = \@intersections;
            }
        }
        if(keys(%found)){
            my ($best_key, $combinations);
            # Find the subset key that has the most combinations in it
            if(keys(%found) > 1){
                my @ordered = sort { @{$found{$a}} <=> @{$found{$b}} } keys(%found);
                $best_key = $found{$ordered[-1]};
            }
            else{
                $best_key = [keys(%found)]->[0];
            }
            $combinations = $found{$best_key};
            $logger->debug(sub { "The best match is $best_key and has : ".@$combinations." results in it" });

            # Find all the devices associated to the combinations we have along with their matching combination count
            my $devices_count = $self->combinations_device_count(@$combinations);
            
            my $max = -1;
            my $max_device_id = undef;
            # Find the combination that is associated to the most combinations
            while(my ($device_id, $count) = each(%$devices_count)){
                if($count > $max){
                    $max = $count;
                    $max_device_id = $device_id;
                }
            }

            my (@infos) = $self->_buildResult($max_device_id);
            $logger->trace(sub { "RedisDB took : ".(time-$start) });
            return @infos;
        }
        $i -= 1;
    }

    return ($fingerbank::Status::NOT_FOUND);

}

=head2 combinations_device_count

Get the count of combinations per device ID for a list of combinations

=cut

sub combinations_device_count {
    my ($self, @combination_ids) = @_;

    $self->cache->compute("combinations_device_count_".join(',', @combination_ids), sub {
        my $db = fingerbank::DB->new(schema => "Upstream");
        my $big_or = join(',', @combination_ids);
        $big_or = "($big_or)";
        my $devices_count = $db->handle->storage->dbh->selectall_hashref("select device_id,count(device_id) as device_count from combination where id IN $big_or group by device_id order by device_count DESC", "device_id");
        return { map { $_ => $devices_count->{$_}->{device_count} } keys(%$devices_count) };
    });
    
}

=head2 _buildResult

Build expected resulting output (hash) from the information we got from Redis

=cut

sub _buildResult {
    my ($self, $device_id, $combination_id) = @_;
    my $result = {};

    if(defined($combination_id)){
        my ($status, $combination) = fingerbank::Model::Combination->read($combination_id);
        return $status if ( is_error($status) );
        $result->{score} = $combination->score;
    }
    else {
        $result->{score} = $DEFAULT_SCORE;
    }

    # Get device info
    my ( $status, $device ) = fingerbank::Model::Device->read($device_id, $TRUE);
    return $status if ( is_error($status) );


    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    return ($fingerbank::Status::OK, $result);
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

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

1;
