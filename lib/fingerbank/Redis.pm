package fingerbank::Redis;

=head1 NAME

fingerbank::Source::LocalDB

=head1 DESCRIPTION

Source for interrogating the local Fingerbank databases (Upstream and Local)

=cut

use Moose;

has 'connection' => (is => 'rw', isa => 'Redis::Fast', builder => '_build_redis', lazy => 1);

use Redis::Fast;
use File::Slurp qw(read_file);
use JSON::MaybeXS;
use fingerbank::FilePath qw($COMBINATION_MAP_FILE);
use fingerbank::Config;

our $_CONNECTION;

=head2 _get_combination2device

Build the redis object

=cut

sub _build_redis {
    my ($self) = @_;

    if($_CONNECTION){
        return $_CONNECTION;
    }

    my $Config = fingerbank::Config::get_config;
    my $redis = Redis::Fast->new(
      server => $Config->{redis}->{host}.':'.$Config->{redis}->{port},
      reconnect => 1,
      every => 100,
    ); 
    return $redis;
}

=head2 _get_combination2device

Insert the sets in Redis from the JSON structure in the map file

=cut

sub fill_from_map {
    my ($self) = @_;
    my $content = read_file($COMBINATION_MAP_FILE);
    my $infos = decode_json($content);
    my $redis = $self->connection;

    while(my ($key, $combination_ids) = each(%$infos)){
        $redis->del($key);
        $redis->sadd($key, @{$combination_ids});
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

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

