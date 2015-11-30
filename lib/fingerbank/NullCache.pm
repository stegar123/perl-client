package fingerbank::NullCache;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub get {return undef;}

sub set {return undef;}

sub compute {
    my ($self, $key, $fct) = @_;
    return $fct->();
}

1;
