package fingerbank::Base::Schema;

use Moose;
use namespace::autoclean;
use MooseX::NonMoose;

extends 'DBIx::Class::Core';

__PACKAGE__->meta->make_immutable;

1;
