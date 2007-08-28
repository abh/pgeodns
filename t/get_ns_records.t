use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/get_ns_records.conf'), "load_config");

ok(my ($ans, $add) = ($g->_get_ns_records($g->config('example.com.'))), "get_ns_records - example.com");
is_deeply( [sort map {$_->nsdname} @$ans], ['ns1.default', 'ns2.default'], 'nsdname - example.com');
is_deeply( $add, [], "empty additional section - example.com");

ok(($ans, $add) = ($g->_get_ns_records($g->config('some.example.com.'))), "get_ns_records - some.example.com");
is_deeply( [sort map {$_->nsdname} @$ans], ['ns1.some', 'ns2.some'], 'nsdname - some.example.com');
is($add->[0]->address, '127.0.0.1', 'ip in additional section');

#use Data::Dumper;
#warn Data::Dumper->Dump([\$ans, \$add], [qw(ans add)]);
