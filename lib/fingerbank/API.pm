package fingerbank::API;

use fingerbank::Config;
use fingerbank::Util;
use HTTP::Request;
use URI;
use fingerbank::Util qw(is_enabled);
use fingerbank::NullCache;
use fingerbank::Status;
use JSON::MaybeXS;

use Moose;

has 'host' => (is => 'rw');
has 'port' => (is => 'rw');
has 'use_https' => (is => 'rw');
has 'cache' => (is => 'rw', default => sub { fingerbank::NullCache->new });

sub new_from_config {
    my ($class) = @_;
    my $Config = fingerbank::Config::get_config();
    return $class->new(
        cache => $fingerbank::Config::CACHE,
        map{$_ => $Config->{upstream}->{$_}} qw(host port use_https),
    );
}

sub get_lwp_client {
    #TODO: allow control of usage of the configured proxy
    my $ua = fingerbank::Util::get_lwp_client(keep_alive => 1);
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

sub test_key {
    my ($self, $key) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $req = $self->build_request("GET", "/api/v2/test/key/$key");

    my $res = $self->get_lwp_client->request($req);

    if($res->code == $fingerbank::Status::UNAUTHORIZED) {
        $logger->info("Provided key ($key) is invalid");
        return ($res->code, "Invalid key provided")
    } elsif ($res->code == $fingerbank::Status::FORBIDDEN) {
        my $msg = "Forbidden access to API. Possibly under rate limiting. Message was: ".$res->decoded_content;
        $logger->error($msg);
        return ($res->code, $msg);
    } elsif ($res->is_success) {
        $logger->info("Successfuly tested key $key"); 
        return ($res->code, $res->decoded_content);
    } else {
        my $msg = "Error while testing API key $key. Error was: ".$res->status_line;
        $logger->error($msg);
        return ($res->code, $msg);
    }

}

=head2 account_info

Get the account information for a specific key.
If no key is provided, it will get the account information of the current configured API key

=cut

sub account_info {
    my ($self, $key) = @_;

    $key //= fingerbank::Config::get_config->{upstream}->{api_key};

    my $logger = fingerbank::Log::get_logger;

    my $req = $self->build_request("GET", "/api/v2/users/account_info/$key");

    my $res = $self->get_lwp_client->request($req);

    if($res->is_success) {
        $logger->info("Fetched user account information successfully");
        return ($res->code, decode_json($res->decoded_content));
    }
    else {
        $logger->error("Error while fetching account information");
        return ($res->code, $res->decoded_content);
    }
}

1;

