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
  my $self = shift;
  $self->mirror_url("http://mirror.cpan.org/rrlist.txt");
}

sub convert {
  my $self = shift;
  my $file = $self->data_file;
  open DATA, $file or die "Could not open $file: $!";
  my @lb_data = ();
  while (<DATA>) {
    next unless m/\S/;
    chomp;
    my ($url, $host, $bandwidth, $contact, $country) = map { $_ =~ s/\s*$//; $_ } split /\t/, $_;
    next unless $url =~ m!ftp://[^/]+/pub/CPAN/?\b!;
    #print "$host / $bandwidth / $country\n";
    my $ip = join ".", unpack('C4',((gethostbyname($host))[4])[0]); 
    
    next if $ip eq "192.75.95.77";

    my $country_code = $country_code{$country};
    my $continent    = $country_continent{$country} or warn "no continent for [$country]\n";
    $continent =~ s/ /-/g;

    push @lb_data, sprintf "%5i %-30s %-15s ftp.cpan %-11s %-20s %-11s %-20s", 1000, "$host.", $ip,
       ($country_code ? "ftp.$country_code.cpan" : ""),
       ($continent    ? "ftp.$continent.cpan"    : ""),
       ($country_code ? "ftp.cpan.$country_code" : ""),
       ($continent    ? "ftp.cpan.$continent"    : ""),
  }
  close DATA or die "Could not close $file: $!";

  $self->lb_list(\@lb_data);

#  print FILE "$weight $host $ip $aliases{$host}\n";

}

1;

