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

ok(my @ans = $g->reply_handler("some.example.com", "IN", "SOA", "192.168.0.10"), "reply_handler test");
is($ans[1]->[0]->mname, 'ns1.some', 'correct soa mname');

ok(my @ans = $g->reply_handler("subzone.some.example.com", "IN", "SOA", "192.168.0.10"), "reply_handler SOA, no record");
ok(!@{ $ans[1] }, 'should not get any records back');

ok(@ans = $g->reply_handler("some.example.com", "IN", "ANY", "192.168.0.10"), "reply_handler test - ANY");
#warn Data::Dumper->Dump([\@ans], [qw(ans)]);

ok((($soa) = grep { $_->type eq 'SOA' } @{$ans[1]}), 'parse soa record from replies');
is( $soa && $soa->mname, 'ns1.some', 'correct soa mname from ANY request');

# use Data::Dumper;
# warn Data::Dumper->Dump([\$soa], [qw(soa)]);
