package Poller::CPAN;
use strict;
use Poller;
use vars qw(@ISA);
@ISA = qw(Poller);
use Regions qw(%country_code %country_continent);
use LWP::Simple qw(mirror RC_OK RC_NOT_MODIFIED);

sub new {
  warn "loading CPAN poller module ...";
  my $proto = shift;
  my $class = ref($proto) || $proto;
  $class->SUPER::new();
}

sub check_data {
  my $mirror_rv = mirror("http://mirror.cpan.org/rrlist.txt", "data/CPAN.data");
  if ($mirror_rv == RC_NOT_MODIFIED) {
    return 0;
  }
  unless ($mirror_rv == RC_OK) {
    print "poller could not get rrlist: $mirror_rv\n";
    return 0
  }
  1;
}

sub convert {
  my $self = shift;
  open DATA, "data/CPAN.data" or die "Could not open data/CPAN.data: $!";
  my @lb_data = ();
  while (<DATA>) {
    next unless m/\S/;
    chomp;
    my ($url, $host, $bandwidth, $contact, $country) = map { $_ =~ s/\s*$//; $_ } split /\t/, $_;
    next unless $url =~ m!ftp://[^/]+/pub/CPAN/!;
    #print "$host / $bandwidth / $country\n";
    my $ip = join ".", unpack('C4',((gethostbyname($host))[4])[0]); 

    my $country_code = $country_code{$country};
    my $continent    = $country_continent{$country};
    $continent =~ s/ /-/g;

    push @lb_data, sprintf "%5i %-30s %-15s ftp.cpan %-11s %-20s", 1000, "$host.", $ip,
       ($country_code ? "ftp.$country_code.cpan" : ""),
       ($continent    ? "ftp.$continent.cpan"    : ""),
  }
  close DATA or die "Could not close data/CPAN.data: $!";

  $self->lb_list(\@lb_data);

#  print FILE "$weight $host $ip $aliases{$host}\n";

}

1;

