
package DNS;


require Exporter;

@ISA = (Exporter);

@EXPORT = qw(
  QR_MASK OP_MASK AA_MASK TC_MASK RD_MASK RA_MASK Z_MASK RCODE_MASK
  QR_SHIFT OP_SHIFT AA_SHIFT TC_SHIFT RD_SHIFT RA_SHIFT Z_SHIFT 
  RCODE_SHIFT

  QPTR PACKETSZ MAXDNAME MAXCDNAME MAXLABEL QFIXEDSZ HEADERLEN
  NAMESERVER_PORT
  QUERY IQUERY STATUS

  UPDATEA UPDATED UPDATEDA UPDATEM UPDATEMA ZONEINIT ZONEREF
  NOERROR FORMERR SERVFAIL NXDOMAIN NOTIMP REFUSED AUTHENBAD NOCHANGE
 
  INDIR_MASK

  T_A T_NS T_MD T_MF T_CNAME T_SOA T_MB T_MG T_MR T_NULL
  T_WKS T_PTR T_HINFO T_MINFO T_MX T_TXT T_UINFO T_UID T_GID
  T_UNSPEC T_UNSPECA T_AXFR T_MAILB T_MAILA T_ANY

  C_IN C_CHAOS C_HS C_HESIOD C_ANY
  
  rr_A rr_CNAME  rr_HINFO rr_MX rr_NS rr_NULL rr_PTR rr_SOA rr_TXT
 
  dns_answer dns_expand dns_simple_dname
);


#----------------

# bit mask to get value
sub QR_MASK     { 0x8000; }   # query(0) or  response(1) bit
sub OP_MASK     { 0x7800; }   # query type
sub AA_MASK     { 0x0400; }   # authoritative answer bit
sub TC_MASK     { 0x0200; }   # truncation bit
sub RD_MASK     { 0x0100; }   # recursion desired bit
sub RA_MASK     { 0x0080; }   # recursion available bit
sub Z_MASK      { 0x0070; }   # reserved bits. must be zero
sub RCODE_MASK  { 0x000f; }   # response code

# number of bits to shift left/right in 16 bit field

sub QR_SHIFT     { 15; }  
sub OP_SHIFT     { 11; }  
sub AA_SHIFT     { 10; }  
sub TC_SHIFT     { 9; }   
sub RD_SHIFT     { 8; }   
sub RA_SHIFT     { 7; }   
sub Z_SHIFT      { 4; }   
sub RCODE_SHIFT  { 0; }   

# misc constants...

sub QPTR { pack("n",0xc00c); }  # PTR to original domain question in packet

sub PACKETSZ {512;}
sub MAXDNAME {256;}
sub MAXCDNAME {255;}
sub MAXLABEL {63;}
sub QFIXEDSZ {4;}

sub HEADERLEN {12;}

sub NAMESERVER_PORT { 53;}

sub QUERY {0x0;}
sub IQUERY {0x1;}
sub STATUS {0x2;}

%op2a=(
 &QUERY,'QUERY',
 &IQUERY,'IQUERY',
 &STATUS,'STATUS'
);

sub UPDATEA {0x9;}
sub UPDATED {0xa;}
sub UPDATEDA {0xb;}
sub UPDATEM {0xc;}
sub UPDATEMA {0xd;}
sub ZONEINIT {0xe;}
sub ZONEREF {0xf;}

# errors 

sub NOERROR {0;}
sub FORMERR {1;}
sub SERVFAIL {2;}
sub NXDOMAIN {3;}
sub NOTIMP {4;}
sub REFUSED {5;}
sub AUTHENBAD {0xe;}
sub NOCHANGE {0xf;}

%err2a=(
 &NOERROR,'NOERROR',
 &FORMERR,'FORMERR',
 &SERVFAIL,'SERVFAIL',
 &NXDOMAIN,'NXDOMAIN',
 &NOTIMP,'NOTIMP',
 &REFUSED,'REFUSED',
 &AUTHENBAD,'AUTHENBAD',
 &NOCHANGE,'NOCHANGE'
);

sub INDIR_MASK {0xc0;}

sub T_A {1;}
sub T_NS {2;}
sub T_MD {3;}
sub T_MF {4;}
sub T_CNAME {5;}
sub T_SOA {6;}
sub T_MB {7;}
sub T_MG {8;}
sub T_MR {9;}
sub T_NULL {10;}
sub T_WKS {11;}
sub T_PTR {12;}
sub T_HINFO {13;}
sub T_MINFO {14;}
sub T_MX {15;}
sub T_TXT {16;}
sub T_UINFO {100;}
sub T_UID {101;}
sub T_GID {102;}
sub T_UNSPEC {103;}
sub T_UNSPECA {104;}

sub T_AXFR {252;}
sub T_MAILB {253;}
sub T_MAILA {254;}
sub T_ANY {255;}

%type2a=(
 &T_A,'T_A',
 &T_NS,'T_NS',
 &T_MD,'T_MD',
 &T_MF,'T_MF',
 &T_CNAME,'T_CNAME',
 &T_SOA,'T_SOA',
 &T_MB,'T_MB',
 &T_MG,'T_MG',
 &T_MR,'T_MR',
 &T_NULL,'T_NULL',
 &T_WKS,'T_WKS',
 &T_PTR,'T_PTR',
 &T_HINFO,'T_HINFO',
 &T_MINFO,'T_MINFO',
 &T_MX,'T_MX',
 &T_TXT,'T_TXT',
 &T_UINFO,'T_UINFO',
 &T_UID,'T_UID',
 &T_GID,'T_GID',
 &T_UNSPEC,'T_UNSPEC',
 &T_UNSPECA,'T_UNSPECA',
 &T_AXFR,'T_AXFR',
 &T_MAILB,'T_MAILB',
 &T_MAILA,'T_MAILA',
 &T_ANY,'T_ANY'
);

sub C_IN {1;}
sub C_CHAOS {3;}
sub C_HS {4;}
sub C_HESIOD {4;}
sub C_ANY {255;}

%class2a=(
 &C_IN,'C_IN',
 &C_CHAOS,'C_CHAOS',
 &C_HS,'C_HS',
 &C_HESIOD,'C_HESIOD',
 &C_ANY,'C_ANY'
);

sub dns_answer {
  local($name,$type,$class,$ttl,$rdata) = @_;
  local($rec);
  $rec  = $name;
  $rec .= pack("n n N n",$type,$class,$ttl,length($rdata));
  $rec .= $rdata;
}
  
sub rr_A {
  local($address) = @_;
  return pack("N",$address);
}

sub rr_CNAME {
  local($dname) = @_;
  return &dns_simple_dname($dname);
}

sub rr_HINFO {
  local($cpu,$os) = @_;
   return sprintf("%c%s%c%s",length($cpu),$cpu,length($os),$os);
}

sub rr_MX {
  local($pref,$exchange) = @_;
  return pack("n",$pref) . &dns_simple_dname($exchange);
}

sub rr_NS {
  local($dname) = @_;
  return &dns_simple_dname($dname);
}

sub rr_NULL {
  local($buff) = @_;
  return $buff;
}

sub rr_PTR {
  local($dname) = @_;
  return &dns_simple_dname($dname);
}

sub rr_SOA {
  local($mname,$rname,$serial,$refresh,$retry,$expire,$minimum) = @_;
  return &dns_simple_dname($mname) . &dns_simple_dname($rname) 
     . pack("NNNNN",$serial,$refresh,$retry,$expire,$minimum);
}

sub rr_TXT {
  local($text) = @_;
  return pack("C",length($text)) . $text;
}

sub dns_simple_dname {
  my $dname = shift;
  my $result;
  foreach my $label (split(/\./,$dname)){
    $result .= sprintf("%c%s",length($label),$label);
  }
  $result .= sprintf("%c",0);
  return $result;
}

#
# expand compressed domain name
#

sub dns_expand {
  local(*msg,$comp_dn,*result,*comp_len) = @_;
  my($cp,$n,$c,$checked);
  
  $result = '';
  $comp_len = -1;
  $cp = $comp_dn;

  while ($n = ord(substr($msg,$cp++,1))) {
     if ( ($n & INDIR_MASK) == 0) {
         $result .= "." if ($result);
         $checked += $n + 1;
         while (--$n >= 0) {
            $result .= "\\" if ( ($c = substr($msg,$cp++,1)) eq '.');
            $result .= $c;
        }
     } else { # pointer, follow it
       $comp_len = $cp - $comp_dn if ($comp_len==-1);
       $cp = (($n & 0x3f) << 8) + ord(substr($msg,$cp,1));
       $checked += 2;
       return 0 if ($checked >= length($msg));
    }
  }
  $comp_len = $cp - $comp_dn if ($comp_len==-1);
  return 1;
}  

1;
