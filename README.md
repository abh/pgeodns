# pgeodns - geo-aware authoriative domain nameserver

pgeodns is an authoritative DNS server that can give different replies
to each client, taking into account the country of origin of the
client and do weighted responses so some records are returned more
than others.

It's used to give IPs of "nearby" servers among the almost 2000
servers registered in the NTP Pool.  The responses are also weighted
by the available bandwidth for each IP (as configued by the server
admins).

It's also used by apache.org for svn.apache.org to send European users
to their European SVN mirror and North American ones to the US based
server. They are providing their configuration as a minimal example:
https://svn.apache.org/repos/infra/infrastructure/trunk/dns/zones/pgeodns.conf
https://svn.apache.org/repos/infra/infrastructure/trunk/dns/zones/geo.apache.org.json

## Installation

   perl Makefile.PL  # will warn if any dependencies are missing
   make 
   make test         # optional
   make install

You'll need the following modules installed, all available from CPAN:
Net::DNS, Geo::IP, List::Util, JSON.  It's optional, but if you
install JSON::XS loading large zone data files will be ever so
slightly faster.

## Configuration

pgeodns needs two configuration files; one simple text file to define
the zones served and some options, and then for each zone a JSON
formatted data file with the zone data.

JSON is relatively easy to read and write for humans, and extremely
easy for computers to use, practically in any language: http://json.org/

The pgeodns.conf file should look like the following.  Only one or
more "base" lines are required.

    # global options

    base some.zone.example.com data/some.file.json
    # options for this zone

    # base another.example.com data/some.file.json
    # options for this zone

## Data file format

See t/example.com.json for a small example for now.


## Command line options

* --config=[ configuration file ]

Name of the configuration file to load; defaults to pgeodns.conf in
the current directory.

* --interface=[ ip | host ]

IP or hostname to listen on (for example 192.168.10.10)

You can specify a comma separated list of IPs. The first IP will be used as the
"server id" when returning status information (see "Special Queries" below), so
if using anycast be sure to put the local/internal IP first or you won't be able
to tell the nodes apart.

* --user=[ username | userid ]

Username or ID to change to after binding to the port.

* --verbose

Provide lots of details for each incoming and outgoing packet.

* --configtest

Load the config and exit.  Exits with 0 as the return value if all is
well.

* --port=[ 53 ]

Specify which port to listen on. Defaults to 53. Only use this in
development or if you are behind a NAT/SNAT device that forwards
queries to a different port.

* --development

This will enable a query to shutdown.$domain to make pgeodns
exit. Obviously not a good idea in production, but can be handy in a
development/testing environment.


## Configuration Options

The options allowed in the 'base' configuration file are

* ns name.server.tld

Add `name.server.tld` as a nameserver for this zone (or globally).  If
you specify one or more NS'es for a zone, it'll override the global
configuration.  You can also specify the ns records in the JSON data,
but doing it in the configuration gives some flexibility for re-using
the data under different namespaces.

* serial 123

Set the serial number of the zone; generally this is better done in
the JSON data.

* ttl 300

Set the default time-to-live for the zone in seconds.

* include filename

Include another filename.

## Special queries

To ease monitoring pgeodns supports some special queries, all `txt` type.

If your application is sensitive to revealing this sort of information you
will need to disable this in the code.

They work with both 'IN' (internet) and 'CH' (chaos) class queries; in the 
future we might only support CH.

* status.pgeodns

Returns a text status with the "id"

* version.pgeodns

Returns a text status with the "version".

For example:

```sh
dig +short -t txt version.pgeodns @a.ntpns.org
"199.15.176.153, v1.41"
```

* _status.pgeodns

Returns a JSON formatted data structure with query count, uptime etc.

### Special query domains

For historical reasons the special queries work on both the 'pgeodns' top level 
domain and on any other configured base domain; combined with working with the
internet class this has the side effect of making it easy to see which server
is responding to your queries:

```sh
$ dig +short -t txt -c in status.pool.ntp.org 
"199.15.176.153, upt: 8901928, q: 993862438, 111.65/qps"
```
