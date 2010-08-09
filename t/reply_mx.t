use Test::More qw(no_plan);
use strict;

my @ans;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/json_config.conf'), "load_config");

#ok(@ans = $g->reply_handler("example.com", "IN", "MX", "192.168.0.10"), "example.com MX");
#warn Data::Dumper->Dump([\@ans], [qw(ans)]);

#ok(@{$ans[1]} == 2, 'got two records');
#is($ans[1]->[0] && $ans[1]->[0]->type, 'MX', 'got MX record');

#is($ans[1]->[0]->address, '192.168.1.2', 'got sane a data');
#is($ans[1]->[0]->ttl, '601', 'got ttl of target record');

