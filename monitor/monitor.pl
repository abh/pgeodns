#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS::Resolver ();
use Time::HiRes qw(time);

use DBI;
use Data::Dumper;
use lib 'lib';
use Monitor qw(read_config dbh);

my $resolv = Net::DNS::Resolver->new();

my $dbh = dbh();

my $config = read_config();
collect_query_counts();

sub collect_query_counts {

    my $sth_insert = $dbh->prepare
        (q[insert into measurements
           (ip, measurement_time, queries, query_time)
           values (?,?,?,?)]
        );

    for my $ip (keys %{$config->{servers}}) {
        my $c = $config->{servers}->{$ip};
        #print "checking $ip/$c->{name}\n";
        $resolv->nameservers($ip);
        my $time = time;
        my $status_query = $resolv->query('status.pool.ntp.org', 'TXT');
        my $elapsed = time - $time;
        for my $rr ($status_query->answer) {
            next unless $rr->type eq "TXT";
            #print $rr->rdatastr, "\n";
            my ($queries) = ($rr->rdatastr =~ m/q: (\d+)/)[0];
            #print "Q: $queries\n";
            my $ip24 = $c->{ip24};
            $sth_insert->execute($ip24, int $time, $queries, $elapsed);
        }
    }

}

1;
