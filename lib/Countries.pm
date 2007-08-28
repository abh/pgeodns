package Countries;
use base qw(Exporter);
@EXPORT_OK = qw(continent);
use strict;

my %country;

while (<DATA>) {
  chomp;
  my ($code, $continent, $name) = split /,/, $_, 3;
  $country{$code} = $continent;
}

sub continent {
  my $cc = shift;
  return $country{$cc} || '';
}

1;

#use Locale::Object::Continent;
#while (<DATA>) {
#  next if m/^\s*#/;
#  chomp;
#  my ($code, $country_name) = split /,/, $_, 2;
#  $country_name =~ s/^"(.*)"$/$1/;
#  my $country = Locale::Object::Country->new( code_alpha2 => $code );
#  next unless $country;
#  my $continent = $country->continent;
#  #warn "mmi: [$country_name]\nloc: [", $country->name,"]\n" if lc $country_name ne lc $country->name;
#  print "no continent for $code / $country\n" unless $continent;
#  printf "%s,%s,%s\n", lc $code,eval {my $x = $continent->name; $x =~ s/\s/-/g; lc $x},$country->name;
#
#}

=pod 

=head1 NAME

GeoDNS::Countries - Map country codes to continents
 
=head1 SYNOPSIS

   use GeoDNS::Countries qw(continent);

   my $continent = continent("dk");
   print $continent;  # "europe"

=head1 DESCRIPTION

=over 4

=item continent( $country_code )

Takes a country code and returns a continent name.  The "continents" are

   africa
   antarctica
   asia
   europe
   north-america
   south-america
   oceania

=back

=head1 BUGS

The mapping could surely be improved and if nothing else then usefully be sub-divided further.

=cut

__DATA__
a1,north-america,"Anonymous Proxy"
a2,north-america,"Satellite Provider"
ap,oceania,Asia/Pacific Region
aq,antarctica,Antarctica
eu,europe,europe
ad,europe,Andorra
ae,asia,United Arab Emirates
af,asia,Afghanistan
ag,north-america,Antigua and Barbuda
ai,north-america,Anguilla
al,europe,Albania
am,europe,Armenia
an,oceania,Netherlands Antilles
ao,africa,Angola
ar,south-america,Argentina
as,north-america,American Samoa
at,europe,Austria
au,oceania,Australia
aw,north-america,Aruba
az,europe,Azerbaijan
ba,europe,Bosnia and Herzegovina
bb,north-america,Barbados
bd,asia,Bangladesh
be,europe,Belgium
bf,oceania,Burkina Faso
bg,europe,Bulgaria
bh,asia,Bahrain
bi,africa,Burundi
bj,africa,Benin
bm,north-america,Bermuda
bn,asia,Brunei Darussalam
bo,south-america,Bolivia
br,south-america,Brazil
bs,north-america,Bahamas
bt,asia,Bhutan
bv,oceania,Bouvet Island
bw,africa,Botswana
by,europe,Belarus
bz,north-america,Belize
ca,north-america,Canada
cc,oceania,Cocos (Keeling) Islands
cd,africa,Congo, the Democratic Republic of the
cf,africa,Central African Republic
cg,africa,Congo
ch,europe,Switzerland
ci,africa,Cote D'Ivoire
ck,oceania,Cook Islands
cl,south-america,Chile
cm,africa,Cameroon
cn,asia,China
co,south-america,Colombia
cr,north-america,Costa Rica
cu,north-america,Cuba
cv,africa,Cape Verde
cx,oceania,Christmas Island
cy,europe,Cyprus
cz,europe,Czech Republic
de,europe,Germany
dj,africa,Djibouti
dk,europe,Denmark
dm,north-america,Dominica
do,north-america,Dominican Republic
dz,africa,Algeria
ec,south-america,Ecuador
ee,europe,Estonia
eg,africa,Egypt
eh,africa,Western Sahara
er,africa,Eritrea
es,europe,Spain
et,africa,Ethiopia
fi,europe,Finland
fj,oceania,Fiji
fk,south-america,Falkland Islands (Malvinas)
fm,oceania,Micronesia, Federated States of
fo,oceania,Faroe Islands
fr,europe,France
fx,europe,France, Metropolitan
ga,africa,Gabon
gb,europe,United Kingdom
gd,north-america,Grenada
ge,europe,Georgia
gf,south-america,French Guiana
gh,africa,Ghana
gi,europe,Gibraltar
gl,europe,Greenland
gm,africa,Gambia
gn,africa,Guinea
gp,south-america,Guadeloupe
gq,africa,Equatorial Guinea
gr,europe,Greece
gs,oceania,South Georgia and the South Sandwich Islands
gt,north-america,Guatemala
gu,north-america,Guam
gw,africa,Guinea-Bissau
gy,south-america,Guyana
hk,asia,Hong Kong
hm,oceania,Heard Island and McDonald Islands
hn,north-america,Honduras
hr,europe,Croatia
ht,north-america,Haiti
hu,europe,Hungary
id,asia,Indonesia
ie,europe,Ireland
il,asia,Israel
in,asia,India
io,oceania,British Indian Ocean Territory
iq,asia,Iraq
ir,asia,Iran, Islamic Republic of
is,europe,Iceland
it,europe,Italy
jm,north-america,Jamaica
jo,asia,Jordan
jp,asia,Japan
ke,africa,Kenya
kg,asia,Kyrgyzstan
kh,asia,Cambodia
ki,oceania,Kiribati
km,africa,Comoros
kn,north-america,Saint Kitts and Nevis
kp,asia,Korea, Democratic People's Republic of
kr,asia,Korea, Republic of
kw,asia,Kuwait
ky,oceania,Cayman Islands
kz,asia,Kazakhstan
la,asia,Lao People's Democratic Republic
lb,asia,Lebanon
lc,north-america,Saint Lucia
li,europe,Liechtenstein
lk,asia,Sri Lanka
lr,africa,Liberia
ls,africa,Lesotho
lt,europe,Lithuania
lu,europe,Luxembourg
lv,europe,Latvia
ly,africa,Libyan Arab Jamahiriya
ma,africa,Morocco
mc,europe,Monaco
md,europe,Moldova, Republic of
mg,africa,Madagascar
mh,oceania,Marshall Islands
mk,europe,Macedonia, the Former Yugoslav Republic of
ml,africa,Mali
mm,asia,Myanmar
mn,asia,Mongolia
mo,asia,Macao
mp,oceania,Northern Mariana Islands
mq,north-america,Martinique
mr,africa,Mauritania
ms,north-america,Montserrat
mt,europe,Malta
mu,africa,Mauritius
mv,asia,Maldives
mw,africa,Malawi
mx,north-america,Mexico
my,asia,Malaysia
mz,africa,Mozambique
na,africa,Namibia
nc,oceania,New Caledonia
ne,africa,Niger
nf,oceania,Norfolk Island
ng,africa,Nigeria
ni,north-america,Nicaragua
nl,europe,Netherlands
no,europe,Norway
np,asia,Nepal
nr,oceania,Nauru
nu,oceania,Niue
nz,oceania,New Zealand
om,asia,Oman
pa,north-america,Panama
pe,south-america,Peru
pf,oceania,French Polynesia
pg,oceania,Papua New Guinea
ph,asia,Philippines
pk,asia,Pakistan
pl,europe,Poland
pm,oceania,Saint Pierre and Miquelon
pn,oceania,Pitcairn
pr,north-america,Puerto Rico
ps,asia,Palestinian Territory, Occupied
pt,europe,Portugal
pw,oceania,Palau
py,south-america,Paraguay
qa,asia,Qatar
re,oceania,Reunion
ro,europe,Romania
ru,europe,Russian Federation
rw,africa,Rwanda
sa,asia,Saudi Arabia
sb,oceania,Solomon Islands
sc,africa,Seychelles
sd,africa,Sudan
se,europe,Sweden
sg,asia,Singapore
sh,oceania,Saint Helena
si,europe,Slovenia
sj,oceania,Svalbard and Jan Mayen
sk,europe,Slovakia
sl,africa,Sierra Leone
sm,europe,San Marino
sn,africa,Senegal
so,africa,Somalia
sr,south-america,Suriname
st,africa,Sao Tome and Principe
sv,north-america,El Salvador
sy,asia,Syrian Arab Republic
sz,africa,Swaziland
tc,north-america,Turks and Caicos Islands
td,africa,Chad
tf,oceania,French Southern Territories
tg,africa,Togo
th,asia,Thailand
tj,asia,Tajikistan
tk,oceania,Tokelau
tl,asia,East Timor
tm,asia,Turkmenistan
tn,africa,Tunisia
to,oceania,Tonga
tr,asia,Turkey
tt,north-america,Trinidad and Tobago
tv,oceania,Tuvalu
tw,asia,Taiwan, Province of China
tz,africa,Tanzania, United Republic of
ua,europe,Ukraine
ug,africa,Uganda
um,north-america,United States Minor Outlying Islands
us,north-america,United States
uy,south-america,Uruguay
uz,asia,Uzbekistan
va,europe,Holy See (Vatican City State)
vc,north-america,Saint Vincent and the Grenadines
ve,south-america,Venezuela
vg,north-america,Virgin Islands, British
vi,north-america,Virgin Islands, U.S.
vn,asia,Vietnam
vu,oceania,Vanuatu
wf,oceania,Wallis and Futuna
ws,oceania,Samoa
ye,asia,Yemen
yt,oceania,Mayotte
yu,europe,Yugoslavia
za,africa,South Africa
zm,africa,Zambia
zr,africa,Zaire
zw,africa,Zimbabwe
