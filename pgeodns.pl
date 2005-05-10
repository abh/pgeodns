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


my $VERSION = ('$Rev$' =~ m/(\d+)/)[0];
my $HeadURL = ('$HeadURL$' =~ m!http:(//[^/]+.*)/pgeodns.pl!)[0];

my %opts = (verbose => 0);
GetOptions (\%opts,
	    'interface=s',
	    'user=s',
	    'verbose!',
	   ) or die "invalid options";

die "--interface [ip|hostname] required\n" unless $opts{interface};
die "--user [user|uid] required\n" unless $opts{user};


sub log {
  warn @_;
}

my $g = GeoDNS->new;
my $stats;
$stats->{started} = time;


sub reply_handler {
  $g->check_config();

  my ($qname, $qclass, $qtype, $peerhost) = @_;
  $qname = lc $qname . ".";

  warn "$peerhost | $qname | $qtype $qclass \n";

  $stats->{qname}->{$qname}++;
  $stats->{qtype}->{$qtype}++;
  $stats->{queries}++;

  my $base = $g->find_base($qname);
  my $config_base = $g->config($base) or return ("SERVFAIL");

  my (@ans, @auth, @add);

  # when are we supposed to add the SOA record and when the NS records here?
  push @auth, @{ ($g->get_ns_records($config_base))[0] };
  push @add,  @{ ($g->get_ns_records($config_base))[1] };

  if ($qname eq $base and $qtype =~ m/^(NS|SOA)$/) {
    if ($qtype eq "SOA" or $qtype eq "ANY") {
      push @ans, $g->get_soa_record($config_base);
    }
    if ($qtype eq "NS" or $qtype eq "ANY") {
      # don't need the authority section for this request ...
      @auth = @add = ();
      push @ans, @{ ($g->get_ns_records($config_base))[0] };
      push @add, @{ ($g->get_ns_records($config_base))[1] };
    }
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  my ($group_host) = ($qname =~ m/(?:(.*)\.)?\Q$base\E$/);
  if ($config_base->{groups}->{$group_host||''}) {
    my $qgroup = $group_host || '';

    my @hosts;
    if ($qtype =~ m/^(A|ANY|TXT)$/) {
      my (@groups) = $g->pick_groups($config_base, $peerhost, $qgroup);
      for my $group (@groups) { 
	push @hosts, $g->pick_hosts($config_base, $group);
	last if @hosts; 
	  # add ">= 2" to force at least two hosts even if the second one won't be as local 
      }
      # only return two hosts
      # @hosts = (@hosts[0,1]) if @hosts > 2;
    }
    
    if ($qtype eq "A" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. $config_base->{ttl} IN A $host->{ip}");
      }
    } 

    if ($qtype eq "TXT" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. $config_base->{ttl} IN TXT '$host->{ip}/$host->{name}'");
      }
    } 

    @auth = ($g->get_soa_record($config_base)) unless @ans;

    # mark the answer as authoritive (by setting the 'aa' flag
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });

  }
  elsif ($config_base->{ns}->{$qname}) {
    push @ans, grep { $_->address eq $config_base->{ns}->{$qname} } @{ ($g->get_ns_records($config_base))[1] };
    @add = grep { $_->address ne $config_base->{ns}->{$qname} } @add;
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  elsif ($qname =~ m/^status\.\Q$base\E$/) {
    my $uptime = time - $stats->{started} || 1;
    # TODO: convert to 2w3d6h format ...
    my $status = sprintf "%s, upt: %i, q: %i, %.2f/qps",
      $opts{interface}, $uptime, $stats->{queries}, $stats->{queries}/$uptime;
    warn Data::Dumper->Dump([\$stats], [qw(stats)]);
    push @ans, Net::DNS::RR->new("$qname. 1 IN TXT '$status'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  elsif ($qname =~ m/^version\.\Q$base\E$/) {
    my $version = "$opts{interface}, Rev #$VERSION $HeadURL";
    push @ans, Net::DNS::RR->new("$qname. 1 IN TXT '$version'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  else {
    @auth = $g->get_soa_record($config_base);
    warn "return cruft ...";
    return ("NXDOMAIN", [], \@auth, [], { aa => 1 });
  }

}

my $localaddr = $opts{interface};

if ($localaddr =~ /[^\d\.]/) {
    my $addr = inet_ntoa((gethostbyname($localaddr))[4]);
    die "could not lookup $localaddr\n" unless $addr;
    $localaddr = $addr;
}

my $ns = Net::DNS::Nameserver->new
  (
   LocalPort    => 53,
   LocalAddr    => $localaddr,
   ReplyHandler => \&reply_handler,
   Verbose      => $opts{verbose},
  );

# print error?
die "couldn't create nameserver object\n" unless $ns;

my $uid = $opts{user};
$uid = getpwnam($uid) or die "could not lookup uid"
 if $uid =~ m/\D/;

setuid($uid) or die "could not setuid: $!";

$g->load_config();

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

=item --verbose

Print even more status output.

=back

=head1 CONFIGURATION

pgeodns.conf in the current directory.  Review it and the included
samples in conf/* until it gets documented. :-)

    
=head1 REFERENCES

RFC2308  http://www.faqs.org/rfcs/rfc2308.html

=head1 BUGS?  COMMENTS?

Send them to ask@develooper.com.

=head1 COPYRIGHT

Copyright 2004-2005 Ask Bjoern Hansen, Develooper LLC

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
