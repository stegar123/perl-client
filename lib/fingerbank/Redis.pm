package fingerbank::Redis;

=head1 NAME

fingerbank::Redis

=head1 DESCRIPTION

To manage the connection to Redis and the data inside it

=cut

use Moose;

has 'connection' => (is => 'rw', isa => 'Redis::Fast', builder => '_build_redis', lazy => 1);

use Redis::Fast;
use File::Slurp qw(read_file);
use JSON::MaybeXS;
use fingerbank::FilePath qw($COMBINATION_MAP_FILE);
use fingerbank::Config;
use fingerbank::Status;
use fingerbank::Util qw(is_success);
use fingerbank::Constant qw($REDIS_RECONNECT_INTERVAL $TRUE);
use Encode qw(encode);
use I18N::Langinfo qw(langinfo CODESET);
use List::MoreUtils qw(natatime);

our $REDIS_DRIVER = "Redis::Fast";

our $SADD_BATCH_BY = 100000;

=head2 _build_redis

Build the redis object

=cut

sub _build_redis {
    my ($self) = @_;

    my $Config = fingerbank::Config::get_config;
    my $redis = $REDIS_DRIVER->new(
      server => $Config->{redis}->{host}.':'.$Config->{redis}->{port},
      reconnect => $TRUE,
      every => $REDIS_RECONNECT_INTERVAL,
    ); 
    return $redis;
}

=head2 fill_from_map

Insert the sets in Redis from the JSON structure in the map file

=cut

sub fill_from_map {
    my ($self) = @_;

    my $os_locale = langinfo(CODESET());

    my $content = read_file($COMBINATION_MAP_FILE);
    my $infos = decode_json($content);
    my $redis = $self->connection;

    while(my ($key, $combination_ids) = each(%$infos)){
        $key = encode($os_locale, $key);
        $redis->del($key);
        if(@{$combination_ids}){
            my $it = natatime $SADD_BATCH_BY, @$combination_ids;
            while (my @ids = $it->()) {
                $redis->sadd($key, @ids);
            }
        }
    }
}

=head2 update_from_api

Updates the local instance with the latest available from the cloud API

=cut

sub update_from_api {
    my ($status, $status_msg) = fingerbank::Config::update_attribute_map();

    if(is_success($status)){
        my $redis = fingerbank::Redis->new;
        $redis->fill_from_map();
        return ($fingerbank::Status::OK, "Updated successfully");
    }
    else {
        return ($status, $status_msg);
    }

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

