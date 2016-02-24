#!/usr/bin/perl

use File::Slurp qw(read_file);
use JSON::MaybeXS;
use Redis::Fast;

my $redis = Redis::Fast->new(
  server => '127.0.0.1:6379',
  name => 'fingerbank',
  reconnect => 1,
  every => 100,
); 


my $content = read_file("supermap.json");
my $infos = decode_json($content);

while(my ($key, $combination_ids) = each(%$infos)){
    $redis->del($key);
    $redis->sadd($key, @{$combination_ids});
}
