#!/usr/bin/perl -w

use Net::DNS;
use Net::DNS::Nameserver;
use Geo::IP;
use strict;
use warnings;
use POSIX qw(setuid);
use Getopt::Long;

use lib 'lib';
use Countries qw(continent);

my $VERSION = ('$Rev$' =~ m/(\d+)/)[0];
my $HeadURL = ('$HeadURL$' =~ m!http:(//[^/]+.*)/pgeodns.pl!)[0];

my %opts = (verbose => 0);
GetOptions (\%opts,
	    'interface=s',
	    'user=s',
	    'verbose!',
	   ) or die "invalid options";

die "--interface [ip] required\n" unless $opts{interface};
die "--user [user|uid] required\n" unless $opts{user};

my $config;
my $stats;
$stats->{started} = time;

sub log {
  warn @_;
}

sub get_ns_records {
  my (@ans, @add);
  my $base = $config->{base};
  for my $ns (keys %{ $config->{ns} }) {
    push @ans, Net::DNS::RR->new("$base 86400 IN NS $ns.");
    push @add, Net::DNS::RR->new("$ns. 86400 IN A $config->{ns}->{$ns}")
      if $config->{ns}->{$ns};
  }
  return (\@ans, \@add);
}

sub get_soa_record {
    Net::DNS::RR->new
	("$config->{base}. 3600 IN SOA $config->{primary_ns};
          dns.perl.org. $config->{serial} 5400 5400 2419200 $config->{ttl}");
}

sub reply_handler {
  check_config();

  my ($qname, $qclass, $qtype, $peerhost) = @_;
  $qname = lc $qname;

  warn "\n$peerhost | $qname | $qtype $qclass \n";

  $stats->{qname}->{$qname}++;
  $stats->{qtype}->{$qtype}++;
  $stats->{queries}++;

  my $base = $config->{base}; 

  my (@ans, @auth, @add);

  # when are we supposed to add the SOA record and when the NS records here?
  push @auth, @{ (get_ns_records)[0] };
  push @add, @{ (get_ns_records)[1] };

  if ($qname eq $base) {
    # return NS

    if ($qtype eq "SOA" or $qtype eq "ANY") {
      push @ans, get_soa_record;
    }
    if ($qtype eq "NS" or $qtype eq "ANY") {
      # don't need the authority section for this request ...
      @auth = @add = ();
      push @ans, @{ (get_ns_records)[0] };
      push @add, @{ (get_ns_records)[1] };
    }
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  if ($qname =~ m/(.*)\.\Q$base\E$/ and $config->{groups}->{$1}) {
    my $qgroup = $1;

    my @hosts;
    if ($qtype =~ m/^(A|ANY|TXT)$/) {
      my (@groups) = pick_groups($peerhost, $qgroup);
      warn "groups: ", join " / ", @groups;  
      for my $group (@groups) { 
	push @hosts, pick_hosts($group);
	last if @hosts; 
	  # add ">= 2" to force at least two hosts even if the second one won't be as local 
      }
      # only return two hosts
      # @hosts = (@hosts[0,1]) if @hosts > 2;
    }
    
    if ($qtype eq "A" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. $config->{ttl} IN A $host->{ip}");
      }
    } 

    if ($qtype eq "TXT" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. $config->{ttl} IN TXT '$host->{ip}/$host->{name}'");
      }
    } 

    @auth = (get_soa_record) unless @ans;

    # mark the answer as authoritive (by setting the 'aa' flag
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });

  }
  elsif ($config->{ns}->{$qname}) {
    push @ans, grep { $_->address eq $config->{ns}->{$qname} } @{ (get_ns_records)[1] };
    @add = grep { $_->address ne  $config->{ns}->{$qname} } @add;
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  elsif ($qname =~ m/^status\.\Q$base\E$/) {
    my $uptime = time - $stats->{started} || 1;
    # TODO: convert to 2w3d6h format ...
    my $status = sprintf "%s, upt: %i, q: %i, %.2f/qps",
      $opts{interface}, $uptime, $stats->{queries}, $stats->{queries}/$uptime;
    warn Data::Dumper->Dump([\$stats], [qw(stats)]);
    push @ans, Net::DNS::RR->new("$qname. 0 IN TXT '$status'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  elsif ($qname =~ m/^version\.\Q$base\E$/) {
    my $version = "Rev #$VERSION $HeadURL";
    push @ans, Net::DNS::RR->new("$qname. 0 IN TXT '$version'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  else {
    @auth = get_soa_record;
    return ("NXDOMAIN", [], \@auth, [], { aa => 1 });
  }

}

my $gi = Geo::IP->new(GEOIP_STANDARD);

my $ns = Net::DNS::Nameserver->new
  (
   LocalPort    => 53,
   LocalAddr    => $opts{interface},
   ReplyHandler => \&reply_handler,
   Verbose      => $opts{verbose},
  );

my $uid = $opts{user};
$uid = getpwnam($uid) or die "could not lookup uid"
 if $uid =~ m/\D/;

setuid($uid) or die "could not setuid: $!";

load_config();

if ($ns) {
  $ns->main_loop;
}
else {
  die "couldn't create nameserver object\n";
}

sub pick_groups {
  my $client_ip = shift;
  my $qgroup    = shift;
  my $country   = lc($gi->country_code_by_addr($client_ip) || 'us');
  my $continent = continent($country) || 'north-america';

  my @candidates = ($country);
  push @candidates, $continent
    unless $continent eq "asia";
  push @candidates, "";  

  my @groups;

  for my $candidate (@candidates) {
    my $group = join ".", grep { $_ } $qgroup,$candidate;
    push @groups, $group if $config->{groups}->{$group};
  }
		     
  @groups;
}

sub pick_hosts {
  my ($group) = shift;

  return unless $config->{groups}->{$group}; 

  my @answer;
  my $max = 2;
  $max = 1 unless scalar @{ $config->{groups}->{$group} };

  my $loop = 0;

  while (@answer < $max) {
    last if ++$loop > 10;  # bad configuration could make us loop ...
    my ($host) = ( @{ $config->{groups}->{$group} } )[rand scalar @{ $config->{groups}->{$group} }];
    next if grep { $host eq $_->{name} } @answer;
    warn "HOST CHOSEN: $host\n";
    push @answer, ({ name => $host, ip => $config->{hosts}->{$host}->{ip} });
  }

  @answer;
}

sub check_config {
  return unless time >= ($config->{last_config_check} + 30);
  for my $file (@{$config->{files}}) {
    load_config(), last 
      if (stat($file->[0]))[9] != $file->[1]
  }
}

sub load_config {

  $config = {};
  $config->{last_config_check} = time;
  $config->{files} = [];

  read_config('pgeodns.conf');

  die "no ns configured in the config file"
    unless $config->{ns};

  $config->{serial} = 1 unless $config->{serial} and $config->{serial} =~ m/^\d+$/;
  $config->{base} ||= 'ddns.develooper.com';
  $config->{ttl}    = 180 unless $config->{ttl} and $config->{ttl} !~ m/\D/;

  use Data::Dumper;
  warn Data::Dumper->Dump([\$config], [qw(config)]);

}

sub read_config {
  my $file = shift;

  open my $fh, $file
    or &log("Can't open config file: $file: $!");

  push @{ $config->{files} }, [$file, (stat($file))[9]];

  while (<$fh>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^\#/ or /^$/;

    if (s/^ns\s+//) {
      my ($name, $ip) = split /\s+/, $_;
      $config->{ns}->{$name} = $ip;
      $config->{primary_ns} = $name
	unless $config->{primary_ns};
    }
    elsif (s/^(serial|base|ttl)\s+//) {
      $config->{$1} = $_;
    }
    elsif (s/^include\s+//) {
      read_config($_);
    }
    else {
      s/^\s*10+\s+//;
      my ($host, $ip, $groups) = split(/\s+/,$_,3);
      $host = "$host." unless $host =~ m/\.$/;  # or should this be the other way around?
      $config->{hosts}->{$host} = { ip => $ip };
      for my $group (split /\s+/, $groups) {
	$config->{groups}->{$group} = [] unless $config->{groups}->{$group};
	push @{$config->{groups}->{$group}}, $host;
      }
    }
    
  }

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

Copyright 2004 Ask Bjoern Hansen, Develooper LLC

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
