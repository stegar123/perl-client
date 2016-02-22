#!/usr/bin/perl

use strict;
use warnings;

use Redis::Fast;
use fingerbank::DB;
use Data::PowerSet qw(powerset);
use Time::HiRes qw(time);


fingerbank::Log::init_logger();
my $logger = fingerbank::Log::get_logger;

my $db = fingerbank::DB->new(schema => "Upstream");
my $combination2device = $db->handle->storage->dbh->selectall_hashref("select id,device_id from combination", "id");

$logger->info("Connecting to redis");

my $redis = Redis::Fast->new(
  server => '127.0.0.1:6379',
  name => 'fingerbank',
  reconnect => 1,
  every => 100,
); 

my %attr_map = (
    mac_vendor => "MAC_Vendor",
    dhcp6_enterprise => "DHCP6_Enterprise",
    dhcp_fingerprint => "DHCP_Fingerprint",
    dhcp6_fingerprint => "DHCP6_Fingerprint",
    dhcp_vendor => "DHCP_Vendor",
    user_agent => "User_Agent",
);

my %search = (
#    "mac_vendor"=>"b84fd5", 
    "mac_vendor"=>"accf85", 
    "dhcp6_enterprise"=>"", 
    "dhcp_fingerprint"=>"", 
    "dhcp6_fingerprint"=>"", 
    "dhcp_vendor"=>"", 
    "user_agent" => "Dalvik/2.1.0 (Linux; U; Android 5.1.1; HUAWEI SCL-L04 Build/HuaweiSCL-L04)",
#    "dhcp_vendor"=>"dhcpcd-5.5.6", 
#    "user_agent" => "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko",
);

my $start = time;

# searching for the perfect match with the empty values
my @sets = map{$attr_map{$_}."-".$search{$_}} keys(%search);
my @found = $redis->sinter(@sets);

if(@found){
    print "Found perfect match ! : ".$found[0];
    exit;
}

# searching for partial matches without the empty values
@sets = map{($search{$_} ne "") ? $attr_map{$_}."-".$search{$_} : ()} keys(%search);

use Data::Dumper;
#print Dumper(\@sets);

#print Dumper([$redis->sinter(@sets)]);

my $failing = 1;
my $i = scalar(@sets);
while($failing && $i > 1){
    my $subsets = powerset({min => $i, max => $i}, @sets);
#    print Dumper($subsets);
    my %found;
    foreach my $subset (@$subsets){
        my @intersections = $redis->sinter(@$subset);
        if(@intersections){
            $found{join(',',@$subset)} = \@intersections;
        }
    }
    if(keys(%found)){
#        $logger->info("Found the following combinations on level $i : ".Dumper(%found));
        my $combinations;
        if(keys(%found) > 1){
            my @ordered = sort { @{$found{$a}} <=> @{$found{$b}} } keys(%found);
            $combinations = $found{$ordered[-1]};
        }
        else{
            $combinations = $found{[keys(%found)]->[0]};
        }
        $logger->info("The best match in found has : ".@$combinations." results in it");
#        my $big_or = join(',', @$combinations);
#        $big_or = "($big_or)";
#        my $devices_count = $db->handle->storage->dbh->selectall_hashref("select id,count(device_id) as device_count from combination where id IN $big_or group by device_id order by device_count DESC", "id");

        my %devices_count;
        foreach my $combination_id (@$combinations){
            my $device_id = $combination2device->{$combination_id}->{device_id};
            $devices_count{$device_id} //= 0;
            $devices_count{$device_id} += 1;
        }

        $logger->info("Found devices : ".Dumper(\%devices_count));

        $failing = 0;
    }
    $i -= 1;
}

print "Took : ".(time-$start);
