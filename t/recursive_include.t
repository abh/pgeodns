use Test::More;
use strict;

eval { use Test::Warn };
plan skip_all => "Need Test::Warn" if $@;

Test::Warn->import('warning_like');

plan tests => 3;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new GeoDNS");
warning_like { $g->load_config('t/recursive_include.conf') } qr/Recursive inclusion/, "Got recursive inclusion warning";

