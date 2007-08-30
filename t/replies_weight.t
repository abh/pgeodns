use Test::More qw(no_plan);
use strict;

use_ok('GeoDNS');
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

my %picks;

for (1..200) {
 my @ans = $g->reply_handler("weight.example.com", "IN", "A", "192.168.0.10");
 $picks{ $ans[1]->[0]->address }++;
}

#use Data::Dumper;
#warn Data::Dumper->Dump([\%picks], [qw(picks)]);

my @picks = sort { $picks{$b} <=> $picks{$a} } keys %picks;
is_deeply(\@picks, [qw(192.168.1.2 192.168.1.3 192.168.1.4)], "results came back in the expected order");
