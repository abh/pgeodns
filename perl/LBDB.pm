package LBDB;

use DNS;

require Exporter;

@ISA = (Exporter);

#@EXPORT = qw(
#  add_static add_dynamic
#);

$default_ttl = 300;

sub check_static {
    my($qname,$qtype,$qclass,$dm,$asking_host) = @_;
    my(@answers,$info,$answers,$classes,@classes,$types);

    #warn "in check_static qname: $qname / info: $info / classes: $classes";

    if ($qclass == C_ANY || $qtype == T_ANY)  {

        if ($qclass == C_ANY) {
            $classes = $static_domain{$qname};
            if (defined $classes) {
               foreach $_ (values %$classes) {
                  push(@classes, $_);
               }
            }
        } else {
           push(@classes, $static_domain{$qname}->{$qclass});
        }

        foreach $types (@classes) {
          if ($types) {
               foreach $_ (values %$types) {
                    push(@answers, $_);        
               } 
          } else {
            return 0;
          }
        }
    } else { 
        push(@answers, $static_domain{$qname}->{$qclass}->{$qtype});
    }

    foreach $info (@answers) {
      if (defined $info) {
	$dm->{'answer'}  .= $info->{"answer"};
	$answers = ($dm->{'ancount'} += $info->{"ancount"});
      }
    }

    return $answers != 0;
}

sub add_static {
  my($domain,$type,$value,$ancount,$class,$ttl) = @_;

  $ancount = 1            unless $ancount;
  $class   = C_IN         unless $class;
  $ttl     = $default_ttl unless $ttl;

  $static_domain{$domain} -> {$class} -> {$type} = {
             "answer" => dns_answer(QPTR,$type,$class,$ttl,$value),
             "ancount" => $ancount
  };

}


sub add_dynamic {
  my($domain, $handler) = @_;

  warn "add_dynamic: $domain";

  $dynamic_domain{$domain} = $handler;
}

sub check_dynamic {
  my($qname,$qtype,$qclass,$dnsmsg,$host_asking) = @_;
  my(@atoms,$dfunc,$residual);


  @atoms = split(/\./,".$qname");
  $dfunc = '';
  $residual = '';

  #warn "in check_dynamic qname: $qname / info: $info / classes: $classes";

  #use Data::Dumper;
  #warn Data::Dumper->Dump([\@atoms, \%dynamic_domain], [qw(atoms dynamic_domain)]);

  while (@atoms) {
    if ($residual) {
      $residual .= "." . shift @atoms;
    }
    else {
      $residual = shift @atoms;
    }
    $domain = join(".", @atoms);
    #warn "while atoms: domain: $domain / residual: $residual";
    last if $dfunc = $dynamic_domain{$domain};
  }

  if ($dfunc) {
    return &$dfunc($domain,$residual,$qtype,$qclass,$dnsmsg,$host_asking);
  } else {
    return 0;
  }
}

1;




