use Test::More qw(no_plan);
use strict;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/read_config.conf'), "load_config");

ok(exists $g->config->{ns}->{'ns1.ddns.develooper.com.'}, "an entry with a trailing dot isn't modified");
ok(exists $g->config->{ns}->{'ddns5.develooper.com.'}, "an entry without a trailing dot is corrected");

ok(utime(time,time, 't/read_config.conf'), 'touch config file');
ok($g->config->{last_config_check} = 1, 'forcing last_config_check to be way in the past');
ok($g->check_config, 'checking config');

ok(exists $g->config->{ns}->{'ddns5.develooper.com.'}, "an entry without a trailing dot is corrected");
