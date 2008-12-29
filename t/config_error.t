use Test::More;
use strict;

eval { use Test::Warn };
plan skip_all => "Need Test::Warn" if $@;

Test::Warn->import('warning_like');

plan tests => 5;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new GeoDNS");
ok($g->load_config('t/pick_groups.conf'), 'load good config');
warning_like { $g->load_config('t/recursive_include.conf') } qr/Recursive inclusion/, "Load bad config; get warning";

is($g->config->{bases}->{"geosearch.perl.org."}->{serial}, 3, "kept old configuration");

exit;

my $c = $g->config;
use Data::Dump qw(dump);
dump($c);
