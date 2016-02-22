#!/usr/bin/perl

use Redis::Fast;
use fingerbank::DB;
    
fingerbank::Log::init_logger();
my $logger = fingerbank::Log::get_logger;

$logger->info("Connecting to redis");

my $redis = Redis::Fast->new(
  server => '127.0.0.1:6379',
  name => 'fingerbank',
  reconnect => 1,
  every => 100,
); 

$logger->info("Starting processing");

my $db = fingerbank::DB->new(schema => "Upstream");

my %infos = (
    DHCP_Fingerprint => {},
    DHCP6_Fingerprint => {},
    DHCP_Vendor => {},
    DHCP6_Enterprise => {},
    User_Agent => {},
    MAC_Vendor => {value_column => "mac"},
);

foreach my $attr (keys(%infos)){
    my $id_column = $infos{$attr}{id_column} // "id";
    my $value_column = $infos{$attr}{value_column} // "value";
    my $fkey_column = $infos{$attr}{fkey_column} // lc($attr)."_id";
    
    my @values = $db->handle->resultset($attr)->all();

    foreach my $elem (@values){
        $logger->info("Processing $attr ".$elem->$id_column);
        my $key = "$attr-".$elem->$value_column;
        $redis->del($key);
        my @combinations = $db->handle->resultset("Combination")->search($fkey_column => $elem->$id_column);
        $redis->sadd($key, map { $_->id } @combinations) if(@combinations);
    }
}
