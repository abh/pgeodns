package GeoDNS;
use strict;
use Net::DNS::RR;
use Countries qw(continent);
use Geo::IP;

my $config;
my $gi = Geo::IP->new(GEOIP_STANDARD);

sub new {
  my $class = shift;
  bless {}, $class;
}

sub config {
  my ($self, $base) = @_;
  return $config unless $base;
  return $config->{bases}->{$base} || {};
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
  map { $base = $_ if $qname =~ m/\Q$_\E$/ and length $_ > length $base } keys %{ $config->{bases} };
  $base;
}

sub load_config {
  my $self = shift;

  $config = {};
  $config->{last_config_check} = time;
  $config->{files} = [];

  read_config( shift || 'pgeodns.conf' );

  warn Data::Dumper->Dump([\$config], [qw(config)]);

  # TODO: make the default serial the timestamp of the newest config file. 
  $config->{serial} = 1 unless $config->{serial} and $config->{serial} =~ m/^\d+$/;
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

  open my $fh, $file
    or &log("Can't open config file: $file: $!");

  push @{ $config->{files} }, [$file, (stat($file))[9]];

  while (<$fh>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^\#/ or /^$/;

    if (s/^(base)\s+//) {
      $_ .= '.' unless m/\.$/;
      $config->{$1} = $_;
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
