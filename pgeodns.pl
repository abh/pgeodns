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

my %opts = (verbose => 0);
GetOptions (\%opts,
	    'interface=s',
	    'user=s',
	    'verbose!',
	   ) or die "invalid options";

die "--interface [ip] required\n" unless $opts{interface};
die "--user [user|uid] required\n" unless $opts{user};

my $config;

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

sub reply_handler {
  check_config();

  my ($qname, $qclass, $qtype, $peerhost) = @_;
  $qname = lc $qname;

  my $base = $config->{base}; 

  my (@ans, @auth, @add);

  push @auth, @{ (get_ns_records)[0] };
  push @add, @{ (get_ns_records)[1] };

  if ($qname eq $base) {
    # return NS

    if ($qtype eq "SOA" or $qtype eq "ANY") {
      my $serial = $config->{serial};
      push @ans, Net::DNS::RR->new
	("$base. 3600 $qclass $qtype $config->{primary_ns};
          dns.perl.org. $serial 5400 5400 2419200 300");
    }
    if ($qtype eq "NS" or $qtype eq "ANY") {
      # don't need the authority section for this request ...
      @auth = @add = ();
      push @ans, @{ (get_ns_records)[0] };
      push @add, @{ (get_ns_records)[1] };
    }
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  if ($qname =~ m/(.*)\Q$base\E$/ and $config->{groups}->{$1}) {
    my $qgroup = $1;

    warn "looking for $qname or something; group is $qgroup ...";

    my (@groups) = pick_groups($peerhost, $qgroup);

    warn "groups: ", join " / ", @groups;  

    my @hosts;
    for my $group (@groups) { 
      push @hosts, pick_hosts($group);
      last if @hosts >= 2;
    }
    
    if ($qtype eq "A" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. 180 IN A $host->{ip}");
      }
    } 

    if ($qtype eq "TXT" or $qtype eq "ANY") {
      for my $host (@hosts) {
	push @ans, Net::DNS::RR->new("$qname. 180 IN TXT '$host->{ip}/$host->{name}'");
      }
    } 

    # mark the answer as authoritive (by setting the 'aa' flag
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });

  }
  elsif($config->{ns}->{$qname}) {
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });

  }
  else {
    return ("NXDOMAIN", [], [], [], { aa => 1 });
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

  warn "pick hosts";

  return unless $config->{groups}->{$group}; 

  warn "still picking hosts"; 

  my @answer;
  my $max = 2;
  $max = 1 unless scalar @{ $config->{groups}->{$group} };

  my $loop = 0;

  while (@answer < $max) {
    last if ++$loop > 10;  # bad configuration could make us loop ...
    my ($host) = ( @{ $config->{groups}->{$group} } )[rand scalar @{ $config->{groups}->{$group} }];
    next if grep { $host eq $_->{name} } @answer;
    warn "HOST CHOSEN: $host";
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
    elsif (s/^(serial|base)\s+//) {
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

A small perl dns server, heavily based on an example from
Net::DNS::Nameserver for distributing different replies based on the
source location of the request.  It uses Geo::IP to make the
determination.

=head1 AUTHOR

Robert Spier <rspier@cpan.org>

=cut
