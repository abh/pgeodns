use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

ok(my $ans = $g->reply_handler("foo.example.com", "IN", "A", "192.168.0.10"), "get basic reply");





