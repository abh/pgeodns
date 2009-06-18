package Monitor;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(read_config dbh);

use JSON 2.12;

use Net::DNS::Resolver ();

my $resolv = Net::DNS::Resolver->new();

my $config_file = 'servers.json';


my $json = JSON->new->relaxed(1);

sub dbh {
    my $dbh = DBI->connect("dbi:SQLite:dbname=measurements.db",
                           "", "", {RaiseError => 1})
      or die "Could not open DB measurements.db: " . DBI->errstr;
    setup_table($dbh);
    return $dbh;
}
sub read_config {

    open my $json_fh, '<', $config_file or die "Could not open $config_file: $!\n";
    my $data = eval { local $/ = undef; <$json_fh> };
    close $json_fh;

    my $config = $json->decode($data);
    die "no zones configured" unless $config->{zones};
    $config->{servers} ||= {};

    my @ips;
    for my $zone (@{$config->{zones}}) {
        my $ns_query = $resolv->query($zone, 'NS');
        for my $rr ($ns_query->answer) {
            next unless $rr->type eq "NS";
            my $ns = $rr->nsdname;

            #print "NS: $ns\n";
            my $a_query = $resolv->query($ns, 'A');
            for my $rr ($a_query->answer) {
                next unless $rr->type eq "A";
                my $ip     = $rr->address;
                my $server = $config->{servers}->{$ip};
                unless ($server) {
                    warn qq[no configuration for\n "$ip": { "name": "" },\n];
                    $config = $config->{servers}->{$ip} = {name => $ns};
                }
                
                #print " - IP: $ip\n";
                $server->{aliases}->{$ns} = 1;
                $server->{zones} ||= [];
                push @{$server->{zones}}, $zone;
            }
        }
    }

    for my $ip (keys %{$config->{servers}}) {
        my $c = $config->{servers}->{$ip};
        my @ip = split /\./, $ip;
        $c->{ip24} = 256*256*256*$ip[0] + 256*256*$ip[1] + 256*$ip[2] + $ip[3];
    }

    return $config;
}

sub setup_table {
    my $dbh = shift;
    $dbh->do
        (q[create table if not exists measurements (
               ip int,
               measurement_time int,
               queries int,
               query_time float
           );
         ]);
}


1;
