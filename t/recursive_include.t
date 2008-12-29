use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok(!eval { $g->load_config('t/recursive_include.conf') }, "recursive_include.conf kills us");
like($@, qr/recursive inclusion of/, "Got proper error");
