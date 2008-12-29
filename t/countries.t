use Test::More qw(no_plan);
use strict;
use_ok("Countries", "continent");

is(continent("dk"), "europe", 'dk is in europe');
is(continent("foobar"), "", 'foobar is not a country code');



