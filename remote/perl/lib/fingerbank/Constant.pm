package fingerbank::Constant;

=head1 NAME

fingerbank::Constant

=head1 DESCRIPTION

Constants used in the code to make it more readable.

=cut

use strict;
use warnings;

use Readonly;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw($FALSE $TRUE $YES $NO);
}

=head1 CONSTANTS

=over

=item $FALSE

=item $TRUE

=item $YES

=item $NO

=cut

Readonly::Scalar our $FALSE     => 0;
Readonly::Scalar our $TRUE      => 1;
Readonly::Scalar our $YES       => 'yes';
Readonly::Scalar our $NO        => 'no';

=back

=head1 QUERY PARAMETERS

=over

=item $DHCP_FINGERPRINT

=item $DHCP_VENDOR

=item $USER_AGENT

=item $MAC_VENDOR

=cut

Readonly::Scalar our $DHCP_FINGERPRINT  => 'DHCP_Fingerprint';
Readonly::Scalar our $DHCP_VENDOR       => 'DHCP_Vendor';
Readonly::Scalar our $USER_AGENT        => 'User_Agent';
Readonly::Scalar our $MAC_VENDOR        => 'MAC_Vendor';

=item @QUERY_PARAMETERS

An array containing all the query parameters

=cut

Readonly::Array our @QUERY_PARAMETERS => (
    $DHCP_FINGERPRINT,
    $DHCP_VENDOR,
    $USER_AGENT,
    $MAC_VENDOR,
);

=item %PARENT_IDS

A hash containing the parent ids for the base devices

=cut

Readonly::Hash our %PARENT_IDS => (
    WINDOWS => 1,
    MACOS => 2,
    ANDROID => 202,
    IOS => 193,
    WINDOWS_PHONE => 5474,
    BLACKBERRY => 192,
);

=back

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

1;
