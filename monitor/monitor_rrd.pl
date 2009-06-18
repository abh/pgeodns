#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use Monitor qw(read_config dbh);

use DBI;
use Data::Dumper;
use RRD::Simple;

my $dbh = dbh;

my $config = read_config();


for my $ip (keys %{$config->{servers}}) {
    my $c = $config->{servers}->{$ip};

    my $file = "rrd/$ip.rrd";

    my $rrd = RRD::Simple->new
      (
       file => "rrd/$ip.rrd",
       rrdtool => "/opt/local/bin/rrdtool",
       tmpdir => "/tmp",
       cf => [ qw(AVERAGE MAX MIN) ],
       default_dstype => "DERIVE",
       on_missing_ds => "add",
      );
     $rrd->create('3years',
         queries => 'DERIVE',         
     ) unless -e $file;

    system("rrdtool tune $file --minimum queries:0 --maximum queries:1000");

     my $last = $rrd->last;

     my $data = $dbh->selectall_arrayref
       (q[select measurement_time, queries from measurements
          where ip = ? and measurement_time > ?
          order by measurement_time],
        undef, $c->{ip24}, $last
       );

    for my $r (@$data) {
        next if $last == $r->[0];
        $last = $r->[0];
        $rrd->update($file,
                     $r->[0],
                     queries => $r->[1],
                    );
    }

    
    
    my %rtn = $rrd->graph(
                          destination => "graphs",
                          basename => "$ip",
                          timestamp => "rrd",
                          #periods => [ qw(week month) ], # omit to generate all graphs
                          #sources => [ qw(queries) ],
                          #source_colors => [ qw(ff0000) ],
                          source_labels => [ ("Queries/sec") ],
                          source_drawtypes => [ qw(LINE1) ],
                          line_thickness => 1,
                          extended_legend => 1,
                          title  => "Queries/sec for $ip",
                          width  => '420',
                          height => '150',
                         );

}
