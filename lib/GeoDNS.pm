package GeoDNS;
use strict;
use Net::DNS::RR;
use Countries qw(continent);
use Geo::IP;
use List::Util qw/max/;

my $VERSION = ('$Rev: 347 $' =~ m/(\d+)/)[0];
my $HeadURL = ('$HeadURL: http://svn.develooper.com/repos/pgeodns/trunk/pgeodns.pl $' =~ m!http:(//[^/]+.*)/pgeodns.pl!)[0];

my $config;
my $stats;
$stats->{started} = time;
my $gi = Geo::IP->new(GEOIP_STANDARD);

sub new {
  my $class = shift;
  my %args  = @_;
  bless \%args, $class;
}

sub log {
  warn @_;
}

sub config {
  my ($self, $base) = @_;
  return $config unless $base;
  return $config->{bases}->{$base} || {};
}

sub reply_handler {
  my $self = shift;

  $self->check_config();

  my ($qname, $qclass, $qtype, $peerhost) = @_;
  $qname = lc $qname . ".";

  warn "$peerhost | $qname | $qtype $qclass \n";

  $stats->{qname}->{$qname}++;
  $stats->{qtype}->{$qtype}++;
  $stats->{queries}++;

  my $base = $self->find_base($qname);
  my $config_base = $self->config($base) or return ("SERVFAIL");

  my (@ans, @auth, @add);

  # when are we supposed to add the SOA record and when the NS records here?
  push @auth, @{ ($self->get_ns_records($config_base))[0] };
  push @add,  @{ ($self->get_ns_records($config_base))[1] };

  if ($qname eq $base and $qtype =~ m/^(NS|SOA)$/) {
    if ($qtype eq "SOA" or $qtype eq "ANY") {
      push @ans, $self->get_soa_record($config_base);
    }
    if ($qtype eq "NS" or $qtype eq "ANY") {
      # don't need the authority section for this request ...
      @auth = @add = ();
      push @ans, @{ ($self->get_ns_records($config_base))[0] };
      push @add, @{ ($self->get_ns_records($config_base))[1] };
    }
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  my ($group_host) = ($qname =~ m/(?:(.*)\.)?\Q$base\E$/);
  if ($config_base->{groups}->{$group_host||''}) {
    my $qgroup = $group_host || '';

    my @hosts;
    if ($qtype =~ m/^(A|ANY|TXT)$/) {
      my (@groups) = $self->pick_groups($config_base, $peerhost, $qgroup);
      for my $group (@groups) { 
	push @hosts, $self->pick_hosts($config_base, $group);
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

    @auth = ($self->get_soa_record($config_base)) unless @ans;

    # mark the answer as authoritive (by setting the 'aa' flag
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });

  }
  elsif ($config_base->{ns}->{$qname}) {
    push @ans, grep { $_->address eq $config_base->{ns}->{$qname} } @{ ($self->get_ns_records($config_base))[1] };
    @add = grep { $_->address ne $config_base->{ns}->{$qname} } @add;
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }

  elsif ($qname =~ m/^status\.\Q$base\E$/) {
    my $uptime = time - $stats->{started} || 1;
    # TODO: convert to 2w3d6h format ...
    my $status = sprintf "%s, upt: %i, q: %i, %.2f/qps",
      $self->{interface}, $uptime, $stats->{queries}, $stats->{queries}/$uptime;
    warn Data::Dumper->Dump([\$stats], [qw(stats)]);
    push @ans, Net::DNS::RR->new("$qname. 1 IN TXT '$status'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  elsif ($qname =~ m/^version\.\Q$base\E$/) {
    my $version = "$self->{interface}, Rev #$VERSION $HeadURL";
    push @ans, Net::DNS::RR->new("$qname. 1 IN TXT '$version'") if $qtype eq "TXT" or $qtype eq "ANY";
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1 });
  }
  else {
    @auth = $self->get_soa_record($config_base);
    warn "return cruft ...";
    return ("NXDOMAIN", [], \@auth, [], { aa => 1 });
  }

}


sub get_ns_records {
  my ($self, $config_base) = @_;
  my (@ans, @add);
  my $base = $config_base->{base};
  for my $ns (keys %{ $config_base->{ns} }) {
    push @ans, Net::DNS::RR->new("$base 86400 IN NS $ns.");
    push @add, Net::DNS::RR->new("$ns. 86400 IN A $config_base->{ns}->{$ns}")
      if $config_base->{ns}->{$ns};
  }
  return (\@ans, \@add);
}

sub get_soa_record {
  my ($self, $config_base) = @_;
    Net::DNS::RR->new
	("$config_base->{base}. 3600 IN SOA $config_base->{primary_ns};
          dns.perl.org. $config_base->{serial} 5400 5400 2419200 $config_base->{ttl}");
}

sub pick_groups {
  my $self        = shift;
  my $config_base = shift; 
  my $client_ip   = shift;
  my $qgroup      = shift;

  my $country   = lc($gi->country_code_by_addr($client_ip) || 'us');
  my $continent = continent($country) || 'north-america';

  my @candidates = ($country);
  push @candidates, $continent
    unless $continent eq "asia";
  push @candidates, "";  

  my @groups;

  for my $candidate (@candidates) {
    my $group = join ".", grep { $_ } $qgroup,$candidate;
    push @groups, $group if $config_base->{groups}->{$group};
  }
		     
  @groups;
}

sub pick_hosts {
  my ($self, $config_base, $group) = @_;

  return unless $config_base->{groups}->{$group}; 

  my @answer;
  my $max = 2;
  $max = 1 unless scalar @{ $config_base->{groups}->{$group} };

  my $loop = 0;

  while (@answer < $max) {
    last if ++$loop > 10;  # bad configuration could make us loop ...
    my ($host) = ( @{ $config_base->{groups}->{$group} } )[rand scalar @{ $config_base->{groups}->{$group} }];
    next if grep { $host eq $_->{name} } @answer;
    push @answer, ({ name => $host, ip => $config_base->{hosts}->{$host}->{ip} });
  }

  @answer;
}


sub find_base {
  # should we cache these?
  my ($self, $qname) = @_;
  my $base = "";
  map { $base = $_ if $qname =~ m/(?:^|\.)\Q$_\E$/ and length $_ > length $base } keys %{ $config->{bases} };
  $base;
}

sub load_config {
  my $self = shift;

  $config = {};
  $config->{last_config_check} = time;
  $config->{files} = [];

  read_config( shift || 'pgeodns.conf' );

  warn Data::Dumper->Dump([\$config], [qw(config)]);

  # the default serial is timestamp of the newest config file. 
  $config->{serial} = max map {$_->[1]} @{ $config->{files} } unless $config->{serial} and $config->{serial} =~ m/^\d+$/;
  $config->{ttl}    = 180 unless $config->{ttl} and $config->{ttl} !~ m/\D/;

  for my $base (keys %{$config->{bases}}) {
    my $config_base = $config->{bases}->{$base};

    for my $f (qw(ns primary_ns ttl serial)) {
      $config_base->{$f} = $config->{$f} or die "default $f needed but not set"
	unless $config_base->{$f};
    }

    die "no ns configured in the config file for base $base"
      unless $config_base->{ns};
  }

  use Data::Dumper;
  warn Data::Dumper->Dump([\$config], [qw(config)]);

}

sub read_config {
  my $file = shift;

  if (grep {$_->[0] eq $file} @{ $config->{files} }) {
    warn "Skipping already included '$file'!";
    return;
  }

  open my $fh, $file
    or &log("Can't open config file: $file: $!");

  push @{ $config->{files} }, [$file, (stat($file))[9]];

  while (<$fh>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^\#/ or /^$/;

    if (s/^base\s+//) {
      $_ .= '.' unless m/\.$/;
      $config->{base} = $_;
      $config->{bases}->{$_} ||= { base => $_ };
      next;
    }
    elsif (s/^include\s+//) {
      read_config($_);
      next;
    }

    unless ($config->{base}) {
      if (s/^ns\s+//) {
	my ($name, $ip) = split /\s+/, $_;
	$config->{ns}->{$name} = $ip;
	$config->{primary_ns} = $name
	  unless $config->{primary_ns};
	next;
      }
      elsif (s/^(serial|ttl|primary_ns)\s+//) {
	$config->{$1} = $_;
      }
    }

    die "Bad configuration: [$_], no base defined\n"
      unless $config->{base};

    my $base = $config->{base};
    my $config_base = $config->{bases}->{$base};

    if (s/^ns\s+//) {
      my ($name, $ip) = split /\s+/, $_;
      $config_base->{ns}->{$name} = $ip;
      $config_base->{primary_ns} = $name
	unless $config_base->{primary_ns};
    }
    elsif (s/^(serial|ttl|primary_ns)\s+//) {
      $config_base->{$1} = $_;
    }
    else {
      s/^\s*10+\s+//;
      my ($host, $ip, $groups) = split(/\s+/,$_,3);
      $host = "$host." unless $host =~ m/\.$/;  # or should this be the other way around?
      $config_base->{hosts}->{$host} = { ip => $ip };
      for my $group_name (split /\s+/, $groups) {
	$group_name = '' if $group_name eq '@';
	$config_base->{groups}->{$group_name} ||= [];
	push @{$config_base->{groups}->{$group_name}}, $host;
      }
    }
  }
}

sub check_config {
  return unless time >= ($config->{last_config_check} + 30);
  for my $file (@{$config->{files}}) {
    load_config(), last 
      if (stat($file->[0]))[9] != $file->[1]
  }
}

1;
