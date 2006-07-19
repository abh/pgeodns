use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/find_base.conf'), "load_config with a default serial");
is($g->config->{serial}, (stat('t/find_base.conf'))[9], "default serial is file timestamp");
