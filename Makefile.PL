use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME                => 'pgeodns',
   AUTHOR              => 'Ask Bjoern Hansen <ask@develooper.com>',
   VERSION_FROM        => 'lib/GeoDNS.pm',
   ABSTRACT            => "Perl Geographic DNS Server",
   PL_FILES            => { },
   EXE_FILES           => [ 'pgeodns' ],
   #    PM => {
   #        'GeoDNS.pm' => '$(INST_LIBDIR)/App/HWD.pm',
   #    },
   PREREQ_PM => 
   {
    'Net::DNS'   => 0.67,
    'Geo::IP'    => 1.28,
    'List::Util' => 0,
    'JSON' => 2.12,
    'IO::Socket::INET6' => '2.01',  # ipv6 support for Net::DNS
   },
   MAN3PODS            => { }, # no need for docs on these
   dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean               => { FILES => 'cover_db pm_to_blib' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';

.PHONY: testcover

cover:
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover

MAKE_FRAG
}
