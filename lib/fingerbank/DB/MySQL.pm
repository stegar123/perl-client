package fingerbank::DB::MySQL;

=head1 NAME

fingerbank::DB::MySQL

=head1 DESCRIPTION

Databases related interaction class

=cut

use Moose;

extends 'fingerbank::DB';

use fingerbank::Log;
use fingerbank::Util qw(is_error);
use fingerbank::Status;

has 'username'        => (is => 'rw');
has 'password'        => (is => 'rw');
has 'host'            => (is => 'rw');
has 'database'        => (is => 'rw');

our @schemas = ('Upstream');

our %_HANDLES = ();

=head1 METHODS

=head2 BUILD

=cut


sub _build_handle {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $schema = $self->{schema};

    $logger->trace("Requesting schema '$schema' DB handle");

    # Check if the requested schema is a valid one
    my %schemas = map { $_ => 1 } @schemas;
    if ( !exists($schemas{$schema}) ) {
        $self->status_code($fingerbank::Status::INTERNAL_SERVER_ERROR);
        $self->status_msg("Requested schema '$schema' does not exists");
        $logger->warn($self->status_msg);
        return;
    }

    # Test requested schema DB file validity
    return if is_error($self->_test);

    # Returning the requested schema db handle
    my $handle = "fingerbank::Schema::$schema"->connect("dbi:mysql:database=".$self->database.";host=".$self->host, $self->username, $self->password);
    
    $_HANDLES{$schema} = { handle => $handle };

    return $handle;
}

# TODO - rework this to a real test
sub _test { $_[0]->status_code($fingerbank::Status::OK); return $fingerbank::Status::OK }

sub initialize_from_sqlite {
    my ($self, $from_file) = @_;
    die("Missing or inexisting source SQLite file") unless(defined($from_file) && -f $from_file);

    my $mysql_args = "-h ".$self->host." -u ".$self->username." -p".$self->password;
    my $database = $self->database;
    print `mysql $mysql_args -e 'drop database $database'`;
    print `mysql $mysql_args -e 'create database $database'`;
    print `sqlite3 $from_file .dump | python db/sqlite3-to-mysql.py | mysql $mysql_args $database`;

}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;

