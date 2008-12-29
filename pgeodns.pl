#!/usr/bin/perl -w

use lib 'lib';

use GeoDNS;
use Net::DNS;
use Net::DNS::Nameserver;
use strict;
use warnings;
use POSIX qw(setuid);
use Getopt::Long;
use Socket;

my %opts = (verbose => 0);
GetOptions (\%opts,
	    'interface=s',
	    'user=s',
	    'verbose!',
            'config=s',
	   ) or die "invalid options";

die "--interface [ip|hostname] required\n" unless $opts{interface};
die "--user [user|uid] required\n" unless $opts{user};

my $g = GeoDNS->new(interface   => $opts{interface},
                    debug       => 1,
                    config_file => $opts{config},
                   );

my $localaddr = $opts{interface};

if ($localaddr =~ /[^\d\.]/) {
    my $addr = inet_ntoa((gethostbyname($localaddr))[4]);
    die "could not lookup $localaddr\n" unless $addr;
    $localaddr = $addr;
}

printf "\nStarting GeoDNS %s\n", $g->version_full;

my $ns = Net::DNS::Nameserver->new
  (
   LocalPort    => 53,
   LocalAddr    => $localaddr,
   ReplyHandler => sub { 
       my @reply = $g->reply_handler(@_);
       #warn Data::Dumper->Dump([\@reply], [qw(reply)]);
       @reply
       },
   Verbose      => $opts{verbose},
  );

# print error?
die "couldn't create nameserver object\n" unless $ns;

my $uid = $opts{user};
$uid = getpwnam($uid) or die "could not lookup uid"
 if $uid =~ m/\D/;

setuid($uid) or die "could not setuid: $!";

$g->load_config($opts{config} || 'pgeodns.conf');

if ($ns) {
  $ns->main_loop;
}
else {
  die "couldn't create nameserver object\n";
}



__END__

=pod

=head1 NAME

pgeodns - Perl Geographic DNS Server

=head1 OVERVIEW

A small perl dns server for distributing different replies based on
the source location of the request.  It uses Geo::IP to make the
determination.

=head1 OPTIONS

=over 4

=item --interface [ip]

The interface to bind to.

=item --user [user / uid]

The username or uid to run as after binding to port 53.

=item --config [config file]

Base configuration file; defaults to ./pgeodns.conf

=item --verbose

Print even more status output.

=back

=head1 CONFIGURATION

pgeodns.conf in the current directory.  Review it and the included
samples in config/* until it gets documented. :-)

    
=head1 REFERENCES

RFC2308  http://www.faqs.org/rfcs/rfc2308.html

=head1 BUGS?  COMMENTS?

Send them to ask@develooper.com.

=head1 COPYRIGHT

Copyright 2004-2007 Ask Bjoern Hansen, Develooper LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
