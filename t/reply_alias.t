use Test::More qw(no_plan);
use strict;

my @ans;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

ok(@ans = $g->reply_handler("bar.example.com", "IN", "A", "192.168.0.10"), "bar.example.com A (alias to foo)");
#warn Data::Dumper->Dump([\@ans], [qw(ans)]);
ok(@{$ans[1]} == 1, 'got only one record');
is($ans[1]->[0]->type, 'A', 'got A record');
is($ans[1]->[0]->address, '192.168.1.2', 'got sane a data');
is($ans[1]->[0]->ttl, '601', 'got ttl of target record');

