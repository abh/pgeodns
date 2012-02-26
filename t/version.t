use Test::More;
use strict;
use JSON qw(decode_json);

my @ans;

use_ok('GeoDNS');
my $time = time;
ok(my $g = GeoDNS->new, "new");
ok($g->load_config('t/replies.conf'), "load_config");

ok(my $g2 = GeoDNS->new(server_id => '127.0.0.10'), "new");
ok($g2->load_config('t/replies.conf'), "load_config");

like($g2->version_full, qr/^127.0.0.10, v1\.\d+/, 'full version method');

ok(@ans = $g->reply_handler("status.example.com", "IN", "TXT", "192.168.0.10"), "status request, txt");
like($ans[1]->[0]->rdatastr, qr!q: 1,!, 'one query now');

ok(@ans = $g->reply_handler("version.example.com", "IN", "TXT", "192.168.0.10"), "version request, txt");
like($ans[1]->[0]->rdatastr, qr!v$GeoDNS::VERSION/!, 'got the version back');

ok(sleep 1, 'sleep a second');

ok(@ans = $g->reply_handler("version.example.com", "IN", "ANY", "192.168.0.10"), "version request, any");
like($ans[1]->[0]->rdatastr, qr!v$GeoDNS::VERSION/!, 'got the version back');

ok(@ans = $g->reply_handler("status.example.com", "IN", "ANY", "192.168.0.10"), "status request, any");
like($ans[1]->[0]->rdatastr, qr!q: 4,!, 'four queries now');

ok(@ans = $g->reply_handler("status.pgeodns", "CH", "TXT", "192.168.0.10"), "status request, ch class");
like($ans[1]->[0]->rdatastr, qr!q: 5,!, 'five queries now');

ok(@ans = $g2->reply_handler("status.example.com", "IN", "ANY", "192.168.0.10"), "status request, any");
like($ans[1]->[0]->rdatastr, qr!q: 1,!, 'g2 has only done one query now');

ok(@ans = $g->reply_handler("_status.pgeodns", "IN", "TXT", "192.168.0.10"), "_status request (json), txt");
my $x = join "\n", $ans[1]->[0]->char_str_list;
#warn "[", ref $x, "] $x";
ok(my $data = decode_json($x), "decode json");
like($data->{v}, qr!v$GeoDNS::VERSION/!, 'got the version back');

done_testing();
