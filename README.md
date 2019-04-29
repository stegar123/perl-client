fingerbank
==========

[![pipeline status](https://gitlab.com/inverse-inc/perl-client/badges/master/pipeline.svg)](https://gitlab.com/inverse-inc/perl-client/commits/master)

No! Fingerbank is not an organ bank for nice fingers ;)

It is a database for device fingerprinting based on different properties (DHCP fingerprints, 
DHCP vendors, OUI, user-agents, ...) allowing your applications to fully detect then handle 
a custom workflow based on the device type.

Project homepage: [http://fingerbank.org](http://fingerbank.org)

upstream
--------
Codebase of the master Fingerbank database / interface.

remote
------
Codebase of the application / webservice that runs locally in conjunction with your application and handling local 
Fingerbank database / interface syncing with the upstream.
