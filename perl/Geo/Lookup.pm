package Geo::Lookup;
use strict;
use Geo::IP;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(geo_lookup);

sub geo_lookup {
  my $ip = shift;  # used to take a second $force parameter
  use Geo::IP;
  my $gi = Geo::IP->new(GEOIP_STANDARD);
  my $country = $gi->country_code_by_addr($ip);
  return lc $country || "";
}


1;
