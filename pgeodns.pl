 #!/usr/local/bin/perl 
 
 use Net::DNS;
 use Net::DNS::Nameserver;
 use strict;
 use warnings;

 use Geo::Mirror;

 my $gm = Geo::Mirror->new(mirror_file => '/home/rspier/m.txt');

# my $mirror = $gm->closest_mirror_by_country('us');
# my $mirror = $gm->closest_mirror_by_addr('65.15.30.247');
 
 sub reply_handler {
         my ($qname, $qclass, $qtype, $peerhost) = @_;
         my ($rcode, @ans, @auth, @add);

         if ($qtype eq "A") {
	   if ($qname eq "ftp.cpan.org") {
	     my $m = $gm->find_mirror_by_addr($peerhost);
	     print "*** found $m\n";
	     my ($ttl, $rdata) = (3600, $m);
	     push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
	     $rcode = "NOERROR";
	   }
	   elsif ($qname =~ /^ftp\.([a-z][a-z])\.cpan.org$/) {
	     my $m = $gm->find_mirror_by_country($1);
	     print "*** found $m\n";
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
 
 my $ns = Net::DNS::Nameserver->new(
     LocalPort    => 5353,
     ReplyHandler => \&reply_handler,
     Verbose      => 1,
 );
 
 if ($ns) {
     $ns->main_loop;
   } else {
    die "couldn't create nameserver object\n";
 }
