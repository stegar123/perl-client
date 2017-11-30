package fingerbank::API;

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
        map{$_ => $Config->{upstream}->{$_}} qw(host port use_https),
    );
}

sub get_lwp_client {
    #TODO: allow control of usage of the configured proxy
    my $ua = fingerbank::Util::get_lwp_client();
    $ua->timeout(2);   # An query should not take more than 2 seconds
    return $ua;
}

sub build_uri {
    my ($self, $path) = @_;
    my $proto = is_enabled($self->use_https) ? "https" : "http";
    my $host = $self->host;
    my $port = $self->port;
    my $uri = URI->new("$proto://$host:$port$path");
    return $uri;
}

sub build_request {
    my ($self, $verb, $path) = @_;
    
    my $Config = fingerbank::Config::get_config();

    my $url = $self->build_uri($path);
    $url->query_form(key => $Config->{'upstream'}{'api_key'});

    my $req = HTTP::Request->new($verb => $url->as_string);

    return $req;
}

1;

