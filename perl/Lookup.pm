package Lookup;
use strict;
use DB_File;
use Socket;
use Exporter;
use vars qw(@ISA @EXPORT_OK %db);
@ISA = qw(Exporter);
@EXPORT_OK = qw(lookup);

tie %db, "DB_File", "db/ip_country"
  or die "Cannot open file 'db/ip_country': $!\n";

sub lookup {
  my $ip = shift;
  if (!$db{$ip} or
     (time-(split ":", $db{$ip})[0] > 86400*7)) {
    #warn "Looking up $ip";
    my $name = ip2name($ip);
    warn "name: $name\n";
    $name =~ s/.*\.([^.]+)$/$1/;
    $name = "us"  # blatant assumtions at play
      if $name =~ m/^(com|edu|mil|gov)$/;
    #warn "name2: $name";
    $db{$ip} = time. ":$name";
  }
  (split ":", $db{$ip})[1]
}

sub ip2name {
  my $ip = shift;
  my $hostname = "";
  eval {
    local $SIG{ALRM} = sub { die "TIMEOUT\n" };
    alarm(3);
    $hostname = gethostbyaddr(gethostbyname($ip), AF_INET);
    alarm(0);
  };
  if ($@ =~ /TIMEOUT/) {
    print "got dns timeout for $ip\n";
  }

  $hostname ? $hostname : "";
}

END {
  untie %db;
} 

1;
