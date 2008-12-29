use Test::More qw(no_plan);
use strict;
use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/find_base.conf'), "load_config");
isnt($g->find_base("myexample.net."),      "example.net.",      "find_base(myexample.net)");
is($g->find_base("www.example.net."),      "example.net.",      "find_base(example.net)");
is($g->find_base("www.example.com."),      "example.com.",      "find_base(example.com)");
is($g->find_base("some.example.com."),     "some.example.com.", "find_base(some.example.com)");
is($g->find_base("foo.some.example.com."), "some.example.com.", "find_base(foo.some.example.com)");

is_deeply([ $g->find_base("blah.foo.some.example.com.") ], [ "some.example.com.", 'blah.foo' ], 
          "find_base(blah.foo.some.example.com), list context");

is_deeply([ $g->find_base("some.example.com.") ], [ "some.example.com.", '' ], 
          "find_base(some.example.com), list context");


1;
