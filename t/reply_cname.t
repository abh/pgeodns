use Test::More qw(no_plan);
use strict;

my @ans;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

ok(@ans = $g->reply_handler("www.example.com", "IN", "A", "192.168.0.10"), "www.example.com A (to return cname)");
#warn Data::Dumper->Dump([\@ans], [qw(ans)]);
ok(@{$ans[1]} == 1, 'got only one record');
is($ans[1]->[0]->type, 'CNAME', 'got cname record');
is($ans[1]->[0]->cname, 'geo.bitnames.com', 'got correct cname data');
is($ans[1]->[0]->ttl, '600', 'got default ttl');

ok(@ans = $g->reply_handler("cname-long-ttl.example.com", "IN", "A", "192.168.0.10"), "cname-long-ttl.example.com A (to return cname)");
#warn Data::Dumper->Dump([\@ans], [qw(ans)]);
ok(@{$ans[1]} == 1, 'got only one record');
is($ans[1]->[0]->type, 'CNAME', 'got cname record');
is($ans[1]->[0]->cname, 'geo.bitnames.com', 'got correct cname data');
is($ans[1]->[0]->ttl, '86400', 'got 86400 ttl');
