package Regions;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK
            %continent_country %country_continent
            %country_code %code_country);
@ISA = qw(Exporter);
@EXPORT_OK = qw(%continent_country %country_continent
                %country_code %code_country);

my %continent_country = (
   'africa' => [
      'Algeria',
      'Angola',
      'Benin',
      'Botswana',
      'Burkina Faso',
      'Burundi',
      'Cameroon',
      'Cape Verde',
      'Central African Rep.',
      'Chad',
      'Comoros',
      'Congo',
      'Congo, The Democratic Republic of the',
      'Djibouti',
      'Egypt',
      'Equatorial Guinea',
      'Eritrea',
      'Ethiopia',
      'Gabon',
      'Gambia',
      'Ghana',
      'Guinea',
      'Guinea-Bissau',
      'Ivory Coast',
      'Kenya',
      'Lesotho',
      'Liberia',
      'Libya',
      'Madagascar',
      'Malawi',
      'Mali',
      'Mauritania',
      'Mauritius',
      'Morocco',
      'Mozambique',
      'Namibia',
      'Niger',
      'Nigeria',
      'Rwanda',
      'Sao Tome and Principe',
      'Senegal',
      'Seychelles',
      'Sierra Leone',
      'Somalia',
      'South Africa',
      'Sudan',
      'Swaziland',
      'Tanzania',
      'Togo',
      'Tunisia',
      'Uganda',
      'Zaire',
      'Zambia',
      'Zimbabwe',
   ],

   'asia' => [
      'Afghanistan',
      'Armenia',
      'Azerbaidjan',
      'Bahrain',
      'Bangladesh',
      'Bhutan',
      'Brunei',
      'Burma (Myanmar)',
      'Cambodia',
      'China',
      'Cyprus',
      'India',
      'Indonesia',
      'Iran',
      'Iraq',
      'Israel',
      'Japan',
      'Jordan',
      'Kazakhstan',
      'North Korea',
      'South Korea',
      'Kuwait',
      'Kyrgyzstan',
      'Laos',
      'Lebanon',
      'Malaysia',
      'Maldives',
      'Mongolia',
      'Nepal',
      'Oman',
      'Pakistan',
      'Philippines',
      'Qatar',
      'Saudi Arabia',
      'Singapore',
      'Sri Lanka',
      'Syria',
      'Taiwan',
      'Tajikistan',
      'Thailand',
      'Turkey',
      'Turkmenistan',
      'United Arab Emirates',
      'Uzbekistan',
      'Vietnam',
      'Yemen',
   ],

   'europe' => [
      'Albania',
      'Andorra',
      'Austria',
      'Belarus',
      'Belgium',
      'Bosnia-Herzegovina',
      'Bulgaria',
      'Croatia',
      'Czech Republic',
      'Denmark',
      'Estonia',
      'Faroe Islands',                
      'Finland',
      'France',
      'Georgia',
      'Germany',
      'Great Britain',
      'Greece',
      'Hungary',
      'Iceland',
      'Ireland',
      'Italy',
      'Latvia',
      'Liechtenstein',
      'Lithuania',
      'Luxembourg',
      'Macedonia',
      'Malta',
      'Moldova',
      'Monaco',
      'Netherlands',
      'Norway',
      'Poland',
      'Portugal',
      'Romania',
      'Russian Federation',
      'San Marino',
      'Serbia/Montenegro ',
      'Yugoslavia',
      'Slovakia',
      'Slovenia',
      'Spain',
      'Sweden',
      'Switzerland',
      'Ukraine',
      'United Kingdom',
      'Vatican City',
   ],

   'north america' => [
      'Antigua and Barbuda',
      'Bahamas',
      'Barbados',
      'Belize',
      'Canada',
      'Costa Rica',
      'Cuba',
      'Dominica',
      'Dominican Rep.',
      'El Salvador',
      'Grenada',
      'Guatemala',
      'Haiti',
      'Honduras',
      'Jamaica',
      'Mexico',
      'Nicaragua',
      'Panama',
      'Puerto Rico',                       
      'St. Kitts & Nevis',
      'St. Lucia',
      'St. Vincent & the Grendines',
      'Trinidad & Tobago',
      'United States',
      'USA Government',
      'USA Military',                      
      'Educational',
      'Commercial',                       
   ],

   'oceania' => [
      'Australia',
      'Fiji',
      'Kiribati',
      'Marshall Islands',
      'Micronesia',
      'Nauru',
      'New Zealand',
      'Palau',
      'Papua New Guinea',
      'Samoa',
      'Solomon Islands',
      'Tonga',
      'Tuvalu',
      'Vanuatu',
   ],

   'south america' => [
      'Argentina',
      'Bolivia',
      'Brazil',
      'Chile',
      'Colombia',
      'Ecuador',
      'Guyana',
      'Paraguay',
      'Peru',
      'Suriname',
      'Uruguay',
      'Venezuela',
   ]
);

%code_country = map { s/#.*//; /^\s*(\S+)\s+(.+)/ } split(/\n/, <<EOC);
ad     Andorra, Principality of
ae     United Arab Emirates
af     Afghanistan, Islamic State of
ag     Antigua and Barbuda
ai     Anguilla
al     Albania
am     Armenia
an     Netherlands Antilles
ao     Angola
aq     Antarctica
ar     Argentina
as     American Samoa
at     Austria
au     Australia
aw     Aruba
az     Azerbaidjan
ba     Bosnia-Herzegovina
bb     Barbados
bd     Bangladesh
be     Belgium
bf     Burkina Faso
bg     Bulgaria
bh     Bahrain
bi     Burundi
bj     Benin
bm     Bermuda
bn     Brunei Darussalam
bo     Bolivia
br     Brazil
bs     Bahamas
bt     Bhutan
bv     Bouvet Island
bw     Botswana
by     Belarus
bz     Belize
ca     Canada
cc     Cocos (Keeling) Islands
cf     Central African Republic
cd     Congo, The Democratic Republic of the
cg     Congo
ch     Switzerland
ci     Ivory Coast (Cote D'Ivoire)
ck     Cook Islands
cl     Chile
cm     Cameroon
cn     China
co     Colombia
com    Commercial
cr     Costa Rica
cs     Former Czechoslovakia
cu     Cuba
cv     Cape Verde
cx     Christmas Island
cy     Cyprus
cz     Czech Republic
de     Germany
dj     Djibouti
dk     Denmark
dm     Dominica
do     Dominican Republic
dz     Algeria
ec     Ecuador
edu    Educational
ee     Estonia
eg     Egypt
eh     Western Sahara
er     Eritrea
es     Spain
et     Ethiopia
fi     Finland
fj     Fiji
fk     Falkland Islands
fm     Micronesia
fo     Faroe Islands
fr     France
fx     France (European Territory)
ga     Gabon
gb     Great Britain
gd     Grenada
ge     Georgia
gf     French Guyana
gh     Ghana
gi     Gibraltar
gl     Greenland
gm     Gambia
gn     Guinea
gov    USA Government
gp     Guadeloupe (French)
gq     Equatorial Guinea
gr     Greece
gs     S. Georgia &amp; S. Sandwich Isls.
gt     Guatemala
gu     Guam (USA)
gw     Guinea Bissau
gy     Guyana
hk     Hong Kong
hm     Heard and McDonald Islands
hn     Honduras
hr     Croatia
ht     Haiti
hu     Hungary
id     Indonesia
ie     Ireland
il     Israel
in     India
int    International
io     British Indian Ocean Territory
iq     Iraq
ir     Iran
is     Iceland
it     Italy
jm     Jamaica
jo     Jordan
jp     Japan
ke     Kenya
kg     Kyrgyz Republic (Kyrgyzstan)
kh     Cambodia, Kingdom of
ki     Kiribati
km     Comoros
kn     Saint Kitts &amp; Nevis Anguilla
kp     North Korea
kr     South Korea
kw     Kuwait
ky     Cayman Islands
kz     Kazakhstan
la     Laos
lb     Lebanon
lc     Saint Lucia
li     Liechtenstein
lk     Sri Lanka
lr     Liberia
ls     Lesotho
lt     Lithuania
lu     Luxembourg
lv     Latvia
ly     Libya
ma     Morocco
mc     Monaco
md     Moldavia
mg     Madagascar
mh     Marshall Islands
mil    USA Military
mk     Macedonia
ml     Mali
mm     Myanmar
mn     Mongolia
mo     Macau
mp     Northern Mariana Islands
mq     Martinique (French)
mr     Mauritania
ms     Montserrat
mt     Malta
mu     Mauritius
mv     Maldives
mw     Malawi
mx     Mexico
my     Malaysia
mz     Mozambique
na     Namibia
nato   NATO (this was purged in 1996 - see hq.nato.int)
nc     New Caledonia (French)
ne     Niger
net    Network
nf     Norfolk Island
ng     Nigeria
ni     Nicaragua
nl     Netherlands
no     Norway
np     Nepal
nr     Nauru
nt     Neutral Zone
nu     Niue
nz     New Zealand
om     Oman
org    Non-Profit Making Organisations (sic)
pa     Panama
pe     Peru
pf     Polynesia (French)
pg     Papua New Guinea
ph     Philippines
pk     Pakistan
pl     Poland
pm     Saint Pierre and Miquelon
pn     Pitcairn Island
pr     Puerto Rico
pt     Portugal
pw     Palau
py     Paraguay
qa     Qatar
re     Reunion (French)
ro     Romania
ru     Russian Federation
rw     Rwanda
sa     Saudi Arabia
sb     Solomon Islands
sc     Seychelles
sd     Sudan
se     Sweden
sg     Singapore
sh     Saint Helena
si     Slovenia
sj     Svalbard and Jan Mayen Islands
sk     Slovak Republic
sl     Sierra Leone
sm     San Marino
sn     Senegal
so     Somalia
sr     Suriname
st     Saint Tome (Sao Tome) and Principe
su     Former USSR
sv     El Salvador
sy     Syria
sz     Swaziland
tc     Turks and Caicos Islands
td     Chad
tf     French Southern Territories
tg     Togo
th     Thailand
tj     Tadjikistan
tk     Tokelau
tm     Turkmenistan
tn     Tunisia
to     Tonga
tp     East Timor
tr     Turkey
tt     Trinidad and Tobago
tv     Tuvalu
tw     Taiwan
tz     Tanzania
ua     Ukraine
ug     Uganda
uk     United Kingdom
um     USA Minor Outlying Islands
us     United States
uy     Uruguay
uz     Uzbekistan
va     Holy See (Vatican City State)
vc     Saint Vincent &amp; Grenadines
ve     Venezuela
vg     Virgin Islands (British)
vi     Virgin Islands (USA)
vn     Vietnam
vu     Vanuatu
wf     Wallis and Futuna Islands
ws     Samoa
ye     Yemen
yt     Mayotte
yu     Yugoslavia
za     South Africa
zm     Zambia
zr     Zaire
zw     Zimbabwe
EOC

for my $continent (keys %continent_country) {
  for my $country (@{$continent_country{$continent}}) {
    $country_continent{$country} = $continent;
  }
}

%country_code = reverse %code_country;

#%code_country = (TEST => "BAR");

#use Data::Dumper;
#warn Data::Dumper->Dump([\%code_country], [qw(code_country_in_regions)]);


#for my $cc (keys %code_country) {
#  print "$cc -> $code_country{$cc}\n";
#  print "no continent for $code_country{$cc}\n" 
#     unless $country_continent{$code_country{$cc}};
#}


1;
