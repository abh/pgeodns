package Poller::CPANwww;
use strict;
use Poller;
use vars qw(@ISA);
@ISA = qw(Poller);
use Regions qw(%country_code %country_continent);

sub new {
  warn "loading CPANwww poller module ...";
  my $proto = shift;
  my $class = ref($proto) || $proto;
  $class->SUPER::new();
}

sub check_data {
  my $self = shift;
  $self->mirror_url("http://miette.develooper.com/~ask/CPANwww.txt");
}

sub convert {
  my $self = shift;
  my $file = $self->data_file;
  open DATA, $file or die "Could not open $file: $!";
  my @lb_data = ();
  while (<DATA>) {
    next unless m/\S/;
    next if m/\s*#/;
    chomp;
    my ($url, $host, $bandwidth, $contact, $country) = map { $_ =~ s/\s*$//; $_ } split /\t/, $_;
    #next unless $url =~ m!ftp://[^/]+/pub/CPAN/!;
    #print "$host / $bandwidth / $country\n";
    my $ip = join ".", unpack('C4',((gethostbyname($host))[4])[0]); 

    my $country_code = $country_code{$country};
    my $continent    = $country_continent{$country} or warn "no continent for [$country]\n";
    $continent =~ s/ /-/g;

    push @lb_data, sprintf "%5i %-30s %-15s www.cpan %-11s %-20s", 1000, "$host.", $ip,
       ($country_code ? "www.$country_code.cpan" : ""),
       ($continent    ? "www.$continent.cpan"    : ""),
  }
  close DATA or die "Could not close $file: $!";

  $self->lb_list(\@lb_data);

#  print FILE "$weight $host $ip $aliases{$host}\n";

}

1;

