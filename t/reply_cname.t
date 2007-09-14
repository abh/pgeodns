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
is($ans[1]->[0]->address, 'geo.bitnames.com', 'got correct cname data');

