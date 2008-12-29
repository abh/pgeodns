package Poller::Apache;
use strict;
use Poller;
use vars qw(@ISA);
@ISA = qw(Poller);
use Regions qw(%code_country %country_continent);
use LWP::Simple qw(mirror RC_OK RC_NOT_MODIFIED);

sub check_data {
  my $self = shift;
  warn "checking apache data..";
  my $mirror_rv = mirror("http://www.apache.org/mirrors/mirrors.list", $self->data_file);
  if ($mirror_rv == RC_NOT_MODIFIED) {
    return 0;
  }
  unless ($mirror_rv == RC_OK) {
    print "poller could not get rrlist: $mirror_rv\n";
    return 0;
  }
  1;
}

sub convert {
  my $self = shift;
  open DATA, $self->data_file or die "Could not open ".$self->data_file.": $!";
  my @lb_data = ();
  while (<DATA>) {
    next unless m/\S/;
    chomp;
    my ($type, $country_code, $url, $contact) = (split /\s+/, $_)[0..3];
    next unless $type eq "ftp";
    #print "url1: [$url]\n";
    next unless (my ($host) = ($url =~ m!^ftp://([^/]+)/pub/apache/dist/?$!)[0]);
    print "host: $host / url: $url\n";

    my $ip = join ".", unpack('C4',((gethostbyname($host))[4])[0]); 

    next unless $ip;
    

    my $country      = $code_country{$country_code};
    my $continent    = $country_continent{$country};
    $continent =~ s/ /-/g;

    push @lb_data, sprintf "%5i %-30s %-15s ftp.apache %-11s %-20s", 1000, "$host.", $ip,
       ($country_code ? "ftp.apache.$country_code" : ""),
       ($continent    ? "ftp.apache.$continent"    : ""),
     }
  close DATA or die "Could not close ".$self->data_file." $!";

  $self->lb_list(\@lb_data);

#  print FILE "$weight $host $ip $aliases{$host}\n";

}

1;
