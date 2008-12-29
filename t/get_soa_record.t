use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/get_ns_records.conf'), "load_config");

ok(my ($soa) = (GeoDNS::_get_soa_record($g->config('example.com.'))), "get_soa_record - example.com");
is($soa->mname, 'ns1.default', 'mname - example.com');

ok(($soa) = (GeoDNS::_get_soa_record($g->config('example.net.'))), "get_soa_record - example.net");
is($soa->mname, 'ns2.default', 'mname - example.net');

ok(($soa) = (GeoDNS::_get_soa_record($g->config('some.example.com.'))), "get_soa_record - some.example.com");
is($soa->mname, 'ns1.some', 'mname - some.example.com');

ok(my @ans = $g->reply_handler("some.example.com", "IN", "SOA", "192.168.0.10"), "reply_handler test");
is($ans[1]->[0] && $ans[1]->[0]->mname, 'ns1.some', 'correct soa mname');

ok(@ans = $g->reply_handler("some.example.com", "IN", "ANY", "192.168.0.10"), "reply_handler test - ANY");
ok((($soa) = grep { $_->type eq 'SOA' } @{$ans[1]}), 'parse soa record from basic reply');
is( $soa && $soa->mname, 'ns1.some', 'correct soa mname from ANY request');

# return SOA record in the authoritiative section when we do have data for A records etc
ok(@ans = $g->reply_handler("sub2.one.example.com", "IN", "SOA", "192.168.0.10"), "reply_handler SOA, sub2.one zone");
TODO: {
  local $TODO = 'SOA handling for existing records needs work';
  ok(!@{ $ans[1] }, 'should not get any answer records back');
  ok((($soa) = grep { $_->type eq 'SOA' } @{$ans[2]}), 'parse soa record from authority section (SOA request)');
  is( $soa && $soa->mname, 'ns1.some', 'correct soa mname from ANY request');
};

ok(@ans = $g->reply_handler("subzone.some.example.com", "IN", "SOA", "192.168.0.10"), "reply_handler SOA, subzone");
ok(!@{ $ans[1] }, 'should not get any answer records back');
ok((($soa) = grep { $_->type eq 'SOA' } @{$ans[2]}), 'parse soa record from authority section (SOA request)');
is( $soa && $soa->mname, 'ns1.some', 'correct soa mname from ANY request');

ok(@ans = $g->reply_handler("subzone.some.example.com", "IN", "ANY", "192.168.0.10"), "reply_handler test SOA - ANY");
ok(!@{ $ans[1] }, 'should not get any answer records back');
ok((($soa) = grep { $_->type eq 'SOA' } @{$ans[2]}), 'parse soa record from authority section (ANY request)');
is( $soa && $soa->mname, 'ns1.some', 'correct soa mname from ANY request');


# use Data::Dumper;
# warn Data::Dumper->Dump([\$soa], [qw(soa)]);
