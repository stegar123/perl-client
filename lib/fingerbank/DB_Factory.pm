package fingerbank::DB_Factory;

use Moose;
use namespace::autoclean;

use fingerbank::Config;
use fingerbank::Util qw(is_enabled);
use List::MoreUtils qw(any);

sub instantiate {
    my ($self, %args) = @_;
    
    my $Config = fingerbank::Config::get_config;

    # If MySQL is enabled and that the schema can be handled in MySQL
    if(is_enabled($Config->{mysql}->{state}) && any { $_ eq $args{schema} } @fingerbank::DB::MySQL::schemas) {
        return fingerbank::DB::MySQL->new(%{$Config->{mysql}}, %args);
    }
    else {
        return fingerbank::DB->new(%args);
    }
}

1;
