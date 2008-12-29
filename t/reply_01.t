use Test::More qw(no_plan);
use strict;

my @ans;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

ok(@ans = $g->reply_handler("foo.example.com", "IN", "A", "192.168.0.10"), "get basic reply");
like($ans[1]->[0]->address, qr/192.168.1.[234]/, 'correct A record came back');

ok(@ans = $g->reply_handler("foo.example.com", "IN", "ANY", "192.168.0.10"), "ANY request");
like((map { $_->address } grep { $_->type eq 'A' } @{ $ans[1] })[0], qr/192.168.1.[234]/, 'correct A record came back');

ok(@ans = $g->reply_handler("foo.example.org.local", "IN", "A", "192.168.0.10"), "request for not existing base");
is($ans[0], 'SERVFAIL', 'not existing base returns SERVFAIL');

ok(@ans = $g->reply_handler("foo-not.example.com", "IN", "A", "192.168.0.10"), "request for not existing domain");
is($ans[0], 'NXDOMAIN', 'not existing domain returns NXDOMAIN');

