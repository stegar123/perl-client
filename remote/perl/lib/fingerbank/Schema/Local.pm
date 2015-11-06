package fingerbank::Schema::Local;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::Schema';

our $VERSION = "2.0";

__PACKAGE__->load_classes;

__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('../../../db/upgrade/');

__PACKAGE__->meta->make_immutable;

1;
