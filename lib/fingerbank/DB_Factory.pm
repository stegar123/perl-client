package fingerbank::DB_Factory;

use Moose;
use namespace::autoclean;

use fingerbank::DB::SQLite;
use fingerbank::DB::MySQL;
use fingerbank::Config;
use fingerbank::Log;
use fingerbank::Util qw(is_enabled);
use List::MoreUtils qw(any);

sub instantiate {
    my ($self, %args) = @_;
    
    my $logger = fingerbank::Log::get_logger;
    my $Config = fingerbank::Config::get_config;

    # If MySQL is enabled and that the schema can be handled in MySQL
    if($args{type} eq "MySQL" || (is_enabled($Config->{mysql}->{state}) && any { $_ eq $args{schema} } @fingerbank::DB::MySQL::schemas)) {
        $logger->debug("Using MySQL as database for schema ".$args{schema});
        return fingerbank::DB::MySQL->new(%args, %{$Config->{mysql}});
    }
    else {
        $logger->debug("Using SQLite as database for schema ".$args{schema});
        return fingerbank::DB::SQLite->new(%args);
    }
}

1;
