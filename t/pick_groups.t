use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/pick_groups.conf'), "load_config");

my $config_base = $g->config('example.com.');

# .us
ok(my $groups = [$g->pick_groups($config_base, '64.81.84.162', 'ftp.cpan')], 'pick_groups');
is_deeply($groups, ['ftp.cpan.us', 'ftp.cpan.north-america', 'ftp.cpan']);

# .dk
ok($groups = [$g->pick_groups($config_base, '62.79.99.211', 'ftp.cpan')], 'pick_groups');
is_deeply($groups, ['ftp.cpan.europe', 'ftp.cpan']);

# .jp
ok($groups = [$g->pick_groups($config_base, '61.121.253.84', 'ftp.cpan')], 'pick_groups');
is_deeply($groups, ['ftp.cpan']);


my $config_base = $g->config('example.net.');

# .us
ok(my $groups = [$g->pick_groups($config_base, '64.81.84.162', '')], 'pick_groups');
is_deeply($groups, ['us', 'north-america', '']);

# .br
ok(my $groups = [$g->pick_groups($config_base, '200.189.169.135', '')], 'pick_groups');
is_deeply($groups, ['']);



my $config_base = $g->config('geosearch.perl.org.');

# .us
ok(my $groups = [$g->pick_groups($config_base, '64.81.84.162', '')], 'pick_groups');
is_deeply($groups, ['us', '']);

# localhost
ok(my $groups = [$g->pick_groups($config_base, '127.0.0.1', '')], 'pick_groups');
is_deeply($groups, ['us', '']);


use Data::Dumper;
warn Data::Dumper->Dump([\$groups], [qw(groups)]);


