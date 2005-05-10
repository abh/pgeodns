use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/find_base.conf'), "load_config");
is($g->find_base("www.example.net."),      "example.net.",      "find_base(example.net)");
is($g->find_base("www.example.com."),      "example.com.",      "find_base(example.com)");
is($g->find_base("some.example.com."),     "some.example.com.", "find_base(some.example.com)");
is($g->find_base("foo.some.example.com."), "some.example.com.", "find_base(foo.some.example.com)");

1;