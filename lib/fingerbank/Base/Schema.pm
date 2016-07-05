package fingerbank::Base::Schema;

use Moose;
use namespace::autoclean;
use MooseX::NonMoose;

extends 'DBIx::Class::Core';

sub view_with_named_params {
    my ($class, $view) = @_;
    my @ordered = $view =~ /\$([0-9]+)/g;
    $class->meta->{params} = \@ordered;
    $view =~ s/\$[0-9]+/\?/g;
    $class->result_source_instance->view_definition($view);
    print $class->result_source_instance->view_definition;
}

sub view_bind_params {
    my ($class, $map) = @_;
    my $view_sql = $class->result_source_instance->view_definition();
    my @bind_params;
    foreach my $param (@{$class->meta->{params}}) {
        my $element = $map->[$param-1];
        if(defined($element)){
            push @bind_params, $element;
        }
        else {
            die("Invalid argument $param");
        }
    }
    return \@bind_params;
}

__PACKAGE__->meta->make_immutable;

1;
