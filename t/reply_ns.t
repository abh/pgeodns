use Test::More qw(no_plan);
use strict;

my @ans;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/json_config.conf'), "load_config");

ok(@ans = $g->reply_handler("g.example.org", "IN", "NS", "192.168.0.10"), "g.example.org NS");
ok(@{$ans[1]} == 2, 'got two records');
is($ans[1]->[0] && $ans[1]->[0]->type, 'NS', 'got NS records');
like($ans[1]->[0]->nsdname, qr/ns\d\.example\.org$/, 'got NS overrides for g.example.org');

ok(@ans = $g->reply_handler("example.com", "IN", "NS", "192.168.0.10"), "example.com NS");
ok(@{$ans[1]} == 2, 'got two records');
is($ans[1]->[0] && $ans[1]->[0]->type, 'NS', 'got NS records');
like($ans[1]->[0]->nsdname, qr/ns\d\.example\.net$/, 'got NS from JSON');
