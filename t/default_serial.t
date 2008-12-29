use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");

my $expected_default_serial = (stat('t/find_base.conf'))[9];

ok($g->load_config('t/find_base.conf'), "load_config with a default serial");
is($g->config->{serial}, $expected_default_serial, "default serial is file timestamp");

is($g->config("example.com.")->{serial}, $expected_default_serial, 'default serial for example.com');
is($g->config("example.net.")->{serial}, 123, 'serial override for example.net');

