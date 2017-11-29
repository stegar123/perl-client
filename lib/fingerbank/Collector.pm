package fingerbank::Collector;

use fingerbank::Config;
use fingerbank::Util;
use HTTP::Request;
use URI;
use fingerbank::Util qw(is_enabled);

use Moose;

has 'host' => (is => 'rw');
has 'port' => (is => 'rw');
has 'use_https' => (is => 'rw');

sub new_from_config {
    my ($class) = @_;
    my $Config = fingerbank::Config::get_config();
    return $class->new(
        map{$_ => $Config->{collector}->{$_}} qw(host port use_https),
    );
}

sub get_lwp_client {
    #TODO: allow control of usage of the configured proxy
    my $ua = fingerbank::Util::get_lwp_client();
    $ua->timeout(2);   # An query should not take more than 2 seconds
    return $ua;
}

sub build_request {
    my ($self, $verb, $path) = @_;
    
    my $Config = fingerbank::Config::get_config();

    my $proto = is_enabled($self->use_https) ? "https" : "http";
    my $host = $self->host;
    my $port = $self->port;
    my $url = URI->new("$proto://$host:$port$path");

    my $req = HTTP::Request->new($verb => $url->as_string);
    $req->header(Authorization => "Token ".$Config->{'upstream'}{'api_key'});

    return $req;
}

1;
