use Test::More qw(no_plan);
use strict;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/pick_groups.conf'), "load_config");

my $config_base = $g->config('example.com.');

is(my @ans = $g->pick_hosts($config_base, "ftp.cpan"), 2, "two answers returned (out of 3)");

#use Data::Dumper;
#my $x = $config_base->{groups}->{"ftp.cpan"}->{servers};
#warn Data::Dumper->Dump([\$x], [qw(x)]);

my $first;
foreach my $res (@ans) {
  ok(grep(/^$res->{name}/, map { $_->[1]->[0] } @{$config_base->{groups}->{"ftp.cpan"}->{servers}}), "host belongs to the group");
  is($res->{ip}, $config_base->{hosts}->{$res->{name}}->{ip}, "correct IP returned for host");

  if ($first) {
    isnt($res->{name}, $first, "the same host wasn't returned twice");
  } else {
    $first = $res->{name};
  }
}

