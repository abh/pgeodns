use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/json_config.conf'), "load_config");

ok(my ($ans, $add) = ($g->_get_ns_records($g->config('example.com.'))), "get_ns_records - example.com");
is_deeply( [sort map {$_->nsdname} @$ans], ['ns1.example.net', 'ns2.example.net'], 'nsdname - example.com');

