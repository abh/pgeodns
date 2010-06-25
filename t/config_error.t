use Test::More;
use strict;

BEGIN {
  eval { require Test::Warn };
  plan skip_all => "Need Test::Warn" if $@;
  Test::Warn->import('warning_like');
}

plan tests => 7;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new GeoDNS");

warning_like { ok(!$g->load_config('t/json_config_missing.conf'),
               'loading missing file returns false' )
               } qr/Could not open/,
             'load_config warning when .json config is missing';

ok($g->load_config('t/pick_groups.conf'), 'load good config');

warning_like { $g->load_config('t/recursive_include.conf') } [qr/Recursive inclusion/], "Load bad config; get warning";
is($g->config->{bases}->{"geosearch.perl.org."}->{serial}, 3, "kept old configuration");

