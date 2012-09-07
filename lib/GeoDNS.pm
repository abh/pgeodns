package GeoDNS;
use strict;
use warnings;
use Net::DNS '0.64';
use Countries qw(continent);
use Geo::IP;
use List::Util qw/max shuffle/;
use Carp qw(cluck confess);
use JSON '2.12';
use Data::Dumper;

our $VERSION  = '1.41';

my $git;

if (-e ".git") {
    $git = `git describe`;
    chomp $git if $git;
}

my $gi = Geo::IP->new(GEOIP_STANDARD);

my $json = JSON->new->relaxed(1);
my $json_dns = JSON->new->ascii(1);

sub new {
  my $class = shift;
  my %args  = @_;

  $args{server_id} ||= 'unknown_interface';
  $args{config} = {};
  $args{stats}->{started} = time;

  return bless \%args, $class;
}

sub version {
    my $self = shift;
    return "v$VERSION" . ($git ? "/$git" : "");
}

sub version_full {
    my $self = shift;
    return "$self->{server_id}, ". $self->version;
}

sub config {
  my ($self, $base) = @_;
  return $self->{config} unless $base;
  return $self->{config}->{bases}->{$base}; # returns undef on "invalid" base
}

sub reply_handler {
  my $self = shift;

  $self->check_config();

  my ($domain, $query_class, $query_type, $peer_host) = @_;

  $domain = lc $domain . '.';

  warn "$peer_host | $domain | $query_type $query_class\n" if $self->{log};

  my $stats = $self->{stats};

  $stats->{qname}->{$domain}++;
  $stats->{qtype}->{$query_type}++;
  $stats->{queries}++;

  my ($base, $label) = $self->find_base($domain);
  $base or return 'SERVFAIL';

  my $config_base = $self->config($base);
  my $data        = $config_base->{data};

  my (@ans, @auth, @add);

  my $data_label = $data->{$label} || {};
  my $ttl = ($data_label->{ttl} || $config_base->{ttl});

  #warn Data::Dumper->Dump([\$data_label], [qw(data_label)]);

  if (defined $data_label->{alias}) {
      $label = $data_label->{alias};
      $data_label = $data->{ $label } || {};
      $ttl = ($data_label->{ttl} || $config_base->{ttl});
  }

  # TODO: support the groups stuff for cnames
  if ($data_label->{cname}) {
      push @ans, Net::DNS::RR->new(
                                   name  => $domain,
                                   ttl   => $ttl,
                                   type  => 'CNAME',
                                   cname => $data_label->{cname},
                                  );
      #warn Data::Dumper->Dump([\@ans], [qw(answer)]);
      return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }

  # Get glue records if we have some
  # TODO: figure out when this is necessary - probably never(!)
  push @add, @{ ($self->_get_ns_records($config_base))[1] };

  # TODO: this isn't quite right; the ANSWER section should only have a SOA record
  # when we really have one -- in other cases send back NOERROR, empty ANSWER and 
  # the SOA in the AUTHORITY section
  if ($query_type eq 'SOA' or ($query_type eq 'ANY' and $label eq '')) {
      my $soa = $data_label->{soa} || $data->{''}->{soa};
      push @ans, $soa if $soa;
  }

  if ($domain eq $base and $query_type eq 'NS') {
    if ($query_type eq 'NS') {
      # don't need the authority section for this request ...
      @auth = @add = ();
      push @ans, @{ ($self->_get_ns_records($config_base))[0] };
      push @add, @{ ($self->_get_ns_records($config_base))[1] };
    }
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }

  if ($data->{$label}) {

    my (@v4hosts, @v6hosts);
    if ($query_type =~ m/^(A|AAAA|ANY|TXT)$/x) {
      my (@groups) = $self->pick_groups($config_base, $peer_host, $label);
      for my $group (@groups) { 
	push @v4hosts, $self->pick_hosts($config_base, $group, 'a');
	last if @v4hosts; 
	  # add ">= 2" to force at least two hosts even if the second one won't be as local 
      }
      for my $group (@groups) { 
	push @v6hosts, $self->pick_hosts($config_base, $group, 'aaaa');
	last if @v6hosts; 
	  # add ">= 2" to force at least two hosts even if the second one won't be as local 
      }
    }
    
    if ($query_type eq 'A' or $query_type eq 'ANY') {
      for my $host (@v4hosts) {
          push @ans, Net::DNS::RR->new(
                                       name => $domain,
                                       ttl  => $ttl,
                                       type => 'A',
                                       address => $host->{ip}
                                       );
      }
    } 

    if ($query_type eq 'AAAA' or $query_type eq 'ANY') {
      for my $host (@v6hosts) {
          push @ans, Net::DNS::RR->new(
                                       name => $domain,
                                       ttl  => $ttl,
                                       type => 'AAAA',
                                       address => $host->{ip}
                                       );
      }
    } 

    if ($query_type eq 'TXT' or $query_type eq 'ANY') {
      for my $host (@v4hosts, @v6hosts) {
          push @ans, Net::DNS::RR->new(
                                       name => $domain,
                                       ttl  => $ttl,
                                       type => 'TXT',
                                       txtdata => ($host->{ip} eq $host->{name} 
                                                   ? "$host->{ip}-$host->{weight}"
                                                   : "$host->{ip}/$host->{name}-$host->{weight}"
                                                  ),
                                       );
      }
    } 

    @auth = (_get_soa_record($config_base)) unless @ans;

    # mark the answer as authoritive (by setting the 'aa' flag
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });

  }
  # TODO: these should be converted to A records during the configuration phase
  elsif ($config_base->{data}->{''}->{ns}->{$domain}) {
    push @ans, grep { $_->address eq $config_base->{data}->{''}->{ns}->{$domain} } @{ ($self->_get_ns_records($config_base))[1] };
    @add = grep { $_->address ne $config_base->{data}->{''}->{ns}->{$domain} } @add;
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }
  elsif ($domain =~ m/^_status\.\Q$base\E$/x) {
    my $data = {
        up => ((time - $stats->{started}) || 1),
        id => $self->{server_id},
        qs => $stats->{queries},
        v  => $self->version,
    };
    my $status = $json_dns->encode($data);
    push @ans, Net::DNS::RR->new("$domain. 1 $query_class TXT '$status'") if $query_type eq 'TXT' or $query_type eq 'ANY';
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }
  elsif ($domain =~ m/^status\.\Q$base\E$/x) {
    my $uptime = (time - $stats->{started}) || 1;
    # TODO: convert to 2w3d6h format ...
    my $status = sprintf '%s, upt: %i, q: %i, %.2f/qps',
      $self->{server_id}, $uptime, $stats->{queries}, $stats->{queries}/$uptime;
    #  warn Data::Dumper->Dump([\$stats], [qw(stats)]);
    push @ans, Net::DNS::RR->new("$domain. 1 $query_class TXT '$status'") if $query_type eq 'TXT' or $query_type eq 'ANY';
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }
  elsif ($domain =~ m/^version\.\Q$base\E$/x) {
    my $version = $self->version_full;
    push @ans, Net::DNS::RR->new("$domain. 1 $query_class TXT '$version'") if $query_type eq 'TXT' or $query_type eq 'ANY';
    return ('NOERROR', \@ans, \@auth, \@add, { aa => 1, opcode => '' });
  }
  elsif ($self->{development} and $domain =~ m/^shutdown\./) {
    warn "Got shutdown query; shutting down";
    exit;
  }
  else {
    @auth = _get_soa_record($config_base);
    return ('NXDOMAIN', [], \@auth, [], { aa => 1, opcode => '' });
  }

}

my %ns_cache;

sub _get_ns_records {
  my ($self, $config_base) = @_;
  my (@ans, @add);
  my $base = $config_base->{base};
  my $data = $config_base->{data}->{''};

  for my $ns (keys %{ $data->{ns} }) {
    push @ans, $ns_cache{"NS $ns"} ||= Net::DNS::RR->new("$base 86400 IN NS $ns");
    push @add, $ns_cache{"A $ns"}  ||= Net::DNS::RR->new("$ns. 86400 IN A $data->{ns}->{$ns}")
      if $data->{ns}->{$ns};
  }
  return (\@ans, \@add);
}

sub _get_soa_record {
  my $config_base = shift;
  my ($ttl, $serial) = @{$config_base}{qw(ttl serial)};
  return Net::DNS::RR->new
    ("$config_base->{base}. 3600 IN SOA $config_base->{primary_ns};
      support.bitnames.com. $serial 5400 5400 2419200 $ttl");
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
    unless $continent eq 'asia';
  push @candidates, '';  

  my @groups;

  for my $candidate (@candidates) {
    my $group = join '.', grep { defined $_ and $_ ne '' } $qgroup, $candidate;
    push @groups, $group if $config_base->{data}->{$group};
  }
		     
  return @groups;
}

sub pick_hosts {
  my ($self, $config_base, $group_name, $qtype) = @_;

  my $group = $config_base->{data}->{$group_name};
  return unless $group and $group->{$qtype};

  my @answer;

  my $loop = 0;

  unless ($group->{'total_weight' . $qtype}) {
      # find total weight;
      my $total = 0;
      my @servers = ();
      for (sort { $b->[1] <=> $a->[1] } @{$group->{$qtype}}) {
          $total += $_->[1];
	  # Normalization will do nothing if there is no colon 
	  # in the host name
	  $_->[0] = _normalize_AAAA($_->[0]);
          push @servers, [0,$_];
      }
      $group->{'servers' . $qtype} = \@servers;
      $group->{'total_weight' . $qtype} = $total;
  }

  my $total_weight = $group->{'total_weight' . $qtype};

  #warn Data::Dumper->Dump([\{$group->{servers}}], [qw(servers)]);

  my @picked;

  my $max_hosts = $config_base->{max_hosts} || 2;

  while ($total_weight and @answer < $max_hosts) {
    last if ++$loop > 10;  # bad configuration could make us loop ...

    my $n = int(rand( $total_weight ));
    my $host;
    my $total = 0;
    for (@{$group->{'servers' . $qtype}}) {
        next if $_->[0];
        $total += $_->[1]->[1];
        if ($total > $n) {
            push @picked, $_;
            $_->[0] = 1;
            $total_weight -= $_->[1]->[1];
            $host = $_->[1];
            last;
        }
    }

    my $hostname = $host->[0];

    my $ip;
    if ($hostname =~ m/^\d{1,3}(.\d{1,3}){3}$/x) {
	$ip = $hostname;
    } elsif ($hostname =~ m/:/x) {
	$ip = $hostname;
    } else {
	$ip = $config_base->{hosts}->{$hostname}->{ip};
    }
	
    push @answer, ({ name => $hostname, ip => $ip, weight => $host->[1] });
  }

  map { $_->[0] = 0 } @picked;

  return @answer;
}


sub find_base {
  # should we cache these?
  my ($self, $domain) = @_;
  my $base;
  map { $base = $_ if $domain =~ m/(?:^|\.)\Q$_\E$/x
          and (!$base or length $_ > length $base)
      } keys %{ $self->config->{bases} };

  return $base unless $base and wantarray;

  my ($label) = ($domain =~ m/(?:(.*)\.)? # "group name"
                              \Q$base\E$  # anchor in the base name
                            /x);

  return ($base, $label || '');
}

sub load_config {
  my $self     = shift;
  my $filename = shift or confess "load_config requires a filename";

  my $config = eval { _load_config($filename) };
  if (my $err = $@) {
      warn "Configuration error: $err";
      return 0;
  }
  $self->{config} = $config if $config;

  return 1;
}

sub _load_config {
  my $filename = shift;

  my $config = {};
  $config->{last_config_check} = time;
  $config->{files} = {};
  $config->{first_config_file} = $filename;
  $config->{config_file_stack} = [];

  _read_config( $config, $filename );

  delete $config->{base};

  for my $tld (qw(bind pgeodns)) {
      $config->{bases}->{"$tld."} = {
                                 primary_ns => 'ns.pgeodns.',
                                 serial     => 1,
                                 ttl        => 1,
                                 base       => 'pgeodns.',
                                 data       => { '' => { ns => { 'ns.pgeodns.' => undef } },
                                                 #'status'  => { txt => '__status__'  },
                                                 #'version' => { txt => '__version__' },
                                               },
                                };
  }

  # warn Data::Dumper->Dump([\$config], [qw(config)]);

  # the default serial is timestamp of the newest config file. 
  $config->{serial} = max values %{ $config->{files} }
    unless $config->{serial} and $config->{serial} =~ m/^\d+$/;
  $config->{ttl}    = 180 unless $config->{ttl} and $config->{ttl} !~ m/\D/;

  for my $base (keys %{$config->{bases}}) {
    my $config_base = $config->{bases}->{$base};

    # use default ns entries
    $config_base->{data}->{""}->{ns} ||= $config->{ns};

    # for the old style configs we do this when the first NS is set,
    # but we don't have that cleanup for "pure" json configs
    unless ($config_base->{primary_ns}) {
        ($config_base->{primary_ns}) = sort keys %{$config_base->{data}->{""}->{ns}} if $config_base->{data}->{""}->{ns};
    }

    $config_base->{mtime} = max map { $config->{files}->{$_} } @{$config_base->{files}};
    unless ($config_base->{serial}) {
        $config_base->{serial} = $config_base->{mtime} || $config->{serial};
    }

    for my $f (qw(primary_ns ttl)) {
      $config_base->{$f} = $config->{$f} or die "default $f needed but not set"
	unless $config_base->{$f};
    }

    # make sure it's numeric if exported to JSON
    for my $f (qw(serial ttl)) {
        $config_base->{$f} += 0;
    }

    die "no ns configured in the config file for base $base"
      unless $config_base->{data}->{''}->{ns};

    warn "LEGACY DATA - NOT SUPPORTED - 'groups' configured for $base\n" if $config_base->{groups};

    $config_base->{data}->{''}->{soa} = _get_soa_record($config_base);

    #warn Data::Dumper->Dump([\$config_base], [qw(config_base)]);
  }

  # use Data::Dumper;
  # warn Data::Dumper->Dump([\$config], [qw(config)]);
    
  return $config;
}

  

sub _read_config {
  my $config = shift;
  my $file = shift;

  if (grep {$_ eq $file} @{ $config->{config_file_stack} }) {
    die "Recursive inclusion of $file - parent(s): ", join ', ', @{ $config->{config_file_stack} };
  }

  open my $fh, '<', $file
    or die "Can't open config file: $file: $!\n";

  push @{ $config->{config_file_stack} }, $file;

  $config->{files}->{$file} = (stat($file))[9];

  my $base_ns = 0;

  while (<$fh>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^\#/ or /^$/;
    last if /^__END__$/;

    if (s/^base\s+//) {
      $base_ns = 0;
      my ($base_name, $json_file) = split /\s+/, $_;
      $base_name .= '.' unless $base_name =~ m/\.$/;
      $config->{base} = $base_name;
      my @files = @{ $config->{config_file_stack} };
      if ($json_file) {
          open my $json_fh, '<', $json_file or die "Could not open $json_file: $!\n";
          $config->{files}->{$json_file} = (stat($json_file))[9];
          push @files, $json_file;
          my $data = eval { local $/ = undef; <$json_fh> };
          close $json_fh;
          $config->{bases}->{$base_name} = $json->decode($data);
          $config->{bases}->{$base_name}->{json_config} = 1;
      }
      $config->{bases}->{$base_name}->{files} = \@files;
      $config->{bases}->{$base_name}->{base} = $base_name;
      next;
    }
    elsif (s/^include\s+//) {
      _read_config($config, $_);
      next;
    }

    unless ($config->{base}) {
      # read default configurations
      if (s/^ns\s+//) {
	my ($name, $ip) = split /\s+/, $_;
        $name .= '.' unless $name =~ m/\.$/;
	$config->{ns}->{$name} = $ip;
	$config->{primary_ns} = $name
	  unless $config->{primary_ns};
	next;
      }
      elsif (s/^(serial|ttl|primary_ns)\s+//) {
	$config->{$1} = $_;
        next;
      }
    }

    die "Bad configuration: [$_], no base defined\n"
      unless $config->{base};

    my $base = $config->{base};
    my $config_base = $config->{bases}->{$base};

    if (s/^ns\s+//) {
      if (!$base_ns) {
        # clear NS records from json config if there are overrides
        $base_ns = 1;
        $config_base->{data}->{''}->{ns} = {};
      }
      my ($name, $ip) = split /\s+/, $_;
      $name .= '.' unless $name =~ m/\.$/;  # TODO: refactor this so these lines aren't duplicated
                                            # with the ones above
      $config_base->{data}->{''}->{ns}->{$name} = $ip;
      $config_base->{primary_ns} = $name
	unless $config_base->{primary_ns};
    }
    elsif (s/^(serial|ttl|primary_ns|max_hosts)\s+//) {
      $config_base->{$1} = $_;
    }
    else {
      s/^\s*10+\s+//;
      my ($host, $ip, $groups) = split(/\s+/,$_,3);
      die "Bad configuration line: [$_]\n" unless $groups;
      $host = "$host." unless $host =~ m/\.$/;
      my $rtype = "a";
      if ($ip =~ m/:/){ 
	  $rtype = "aaaa";
      }
      $config_base->{hosts}->{$host} = { ip => $ip };
      for my $group_name (split /\s+/, $groups) {
	$group_name = '' if $group_name eq '@';
	# Add the host to it's group, according to querty type
	$config_base->{data}->{$group_name}->{$rtype} ||= [];
	push @{$config_base->{data}->{$group_name}->{$rtype}}, [ $host, 1 ];
      }
    }
  }
  pop @{ $config->{config_file_stack} };
  return 1;
}

sub check_config {
  my $self = shift;
  return unless time >= ($self->config->{last_config_check} + 30);
  my $first_file = $self->config->{first_config_file};
  cluck 'No "first_file' unless $first_file;
  #return unless $first_file;

  my $reload = 0;

  for my $file (keys %{$self->config->{files}}) {
      my $mtime = $self->config->{files}->{$file};
      if ((stat($file))[9] != $mtime) {
          $reload = 1;
          last;
      }
  }
  if ($reload) {
      eval {
          $self->load_config($first_file);
      };
      if (my $err = $@) {
          warn "Error re-loading configuration: $err\n";
          return 0;
      }
  }
  return 1;
}

sub _normalize_AAAA {
    # This is taken from DNS::RR::AAAA::new_from_string
    # Unfortunately, AAAA.pm does not perform this algorithm
    # for records created from a hash
    my $string = shift;
    if ($string =~ /^(.*):(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	my ($front, $a, $b, $c, $d) = ($1, $2, $3, $4, $5);
	$string = $front . sprintf(":%x:%x",
				   ($a << 8 | $b),
				   ($c << 8 | $d));
    }
			
    if ($string =~ /^(.*)::(.*)$/) {
	my ($front, $back) = ($1, $2);
	my @front = split(/:/, $front);
	my @back  = split(/:/, $back);
	my $fill = 8 - (@front ? $#front + 1 : 0)
	    - (@back  ? $#back  + 1 : 0);
	my @middle = (0) x $fill;
	my @addr = (@front, @middle, @back);
	$string = sprintf("%x:%x:%x:%x:%x:%x:%x:%x",
			  map { hex $_ } @addr);
    }
    return $string;
}


1;


__END__

=head1 NAME

GeoDNS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Instantiates a new GeoDNS object.

=item reply_handler

=item pick_groups

=item pick_hosts

=item pick_host

=item load_config($file_name)

Loads the specified configuration file (usually pgeodns.conf).
Supplemental files are loaded via "include" statements or implicit
JSON file loads from the "base" statement.

=item config

Returns the current configuration hash for the object instance.

=item check_config

Checks if any of the configuration files have changed and initiates a
reload if any file has changed since the last load.  It skips checking
unless it's been more than 30 seconds since the last check.

Called automatically from the reply_handler.

=item find_base($name)

Given a domain name, returns the longest matching configured "base".

=item version

Returns a string with the current version number and git commit (if
run from a git checkout).

=item version_full

Returns a string with the version (see above) prepended with the
server id (interface)

=back

=head1 COPYRIGHT

Copyright 2001-2010 Ask Bjoern Hansen and Develooper LLC.  This work
is distributed under the Apache License 2.0 (see the F<LICENSE> file
for more details).
