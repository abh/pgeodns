use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/get_ns_records.conf'), "load_config");

ok(my ($soa) = ($g->_get_soa_record($g->config('example.com.'))), "get_soa_record - example.com");
is($soa->mname, 'ns1.default', 'mname - example.com');

ok(($soa) = ($g->_get_soa_record($g->config('example.net.'))), "get_soa_record - example.net");
is($soa->mname, 'ns2.default', 'mname - example.net');

ok(($soa) = ($g->_get_soa_record($g->config('some.example.com.'))), "get_soa_record - some.example.com");
is($soa->mname, 'ns1.some', 'mname - some.example.com');

#use Data::Dumper;
#warn Data::Dumper->Dump([\$soa], [qw(soa)]);
