#!/usr/local/bin/perl

use Net::DNS;
use Net::DNS::Nameserver;
use strict;
use warnings;

use Geo::Mirror;

my $gm = Geo::Mirror->new(mirror_file => '/home/rspier/m.txt');

# Geo::Mirror data looks like this...
# 10.0.0.1 us
# 10.0.2.1 ca
# 10.0.2.2 ca
# 10.0.3.1 fr
# 10.0.4.1 jp
# can we base it off this data instead?
# http://miette.develooper.com/~ask/dinamed-conf/dinamed.config.lb

# We also need to figure out some sort of dynamic lookup, because
# Geo::Mirror loads the file once.  (Of course, we dont' want to load
# the file _every_ time.)  Maybe store it in a bdb and reload it
# periodically?  Or a storable dump and check for updates every 5
# minutes?

sub reply_handler {
  my ($qname, $qclass, $qtype, $peerhost) = @_;
  my ($rcode, @ans, @auth, @add);

  $rcode = "NXDOMAIN"; # default error
  my $m;

  if ($qtype eq "A") {
    if ($qname eq "ftp.cpan.org"
	and $m = $gm->find_mirror_by_addr($peerhost) ) {
      # find the closest mirror from around the world
      my ($ttl, $rdata) = (3600, $m);
      push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
      $rcode = "NOERROR";
    }
    elsif ($qname =~ /^ftp\.([a-z][a-z])\.cpan.org$/
	   and $m = $gm->find_mirror_by_country($1)) {
      # country code based stuff
      my ($ttl, $rdata) = (3600, $m);
      push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
      $rcode = "NOERROR";
    } else {
      $rcode = "NXDOMAIN";
    }
  } else {
    $rcode = "NXDOMAIN";
  }

  # mark the answer as authoritive (by setting the 'aa' flag
  return ($rcode, \@ans, \@auth, \@add, { aa => 1 });
}

my $ns = Net::DNS::Nameserver->new
  (
   LocalPort    => 5353,
   ReplyHandler => \&reply_handler,
   Verbose      => 1,
  );

if ($ns) {
  $ns->main_loop;
} else {
  die "couldn't create nameserver object\n";
}

__END__

=pod

=head1 NAME

pgeodns - Perl Geographic DNS Server

=head1 OVERVIEW

A small perl dns server, heavily based on an example from
Net::DNS::Nameserver for distributing different replies based on the
source location of the request.  It uses Geo::IP to make the
determination.

=head1 AUTHOR

Robert Spier <rspier@cpan.org>

=cut
