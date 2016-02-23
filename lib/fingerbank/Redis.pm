package fingerbank::Redis;

use Moose;

has 'connection' => (is => 'rw', isa => 'Redis::Fast', builder => '_build_redis', lazy => 1);

use Redis::Fast;
use File::Slurp qw(read_file);
use JSON::MaybeXS;
use fingerbank::FilePath qw($COMBINATION_MAP_FILE);
use fingerbank::Config;

our $_CONNECTION;

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

1;
