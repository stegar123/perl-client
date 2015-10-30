#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Switch;

BEGIN {
    use lib "/usr/local/fingerbank/lib";
    use fingerbank::Log;
    fingerbank::Log::init_logger;
}

use fingerbank::DB;

unless(@ARGV){
    die pod2usage("\nthe 'database' argument must be 'local', 'upstream' or 'both'\n");
}

my $database = "local";
GetOptions ( "database=s" => \$database, );
$database = lc($database);
if ( !($database =~ /^local|upstream|both$/) ) {
    pod2usage("\nthe 'database' argument must be 'local', 'upstream' or 'both'\n");
}

switch ( $database ) {
    case 'local' {
        `/usr/local/fingerbank/db/upgrade.pl`;
    }

    case 'upstream' {
        fingerbank::DB::update_upstream;
    }

    case 'both' {
        fingerbank::DB::initialize_local;
        fingerbank::DB::update_upstream;
    }
}

1;
