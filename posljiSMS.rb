#coding: utf-8
###################################################################
# Priznam, da me je primera v PHP-ju ki ga dobite na Mobitelovi spletni
# strani malo strah, pa čeprav sem vse skupaj uspešno uporabljal več kot
# eno leto. Zato sem vse skupaj napisal v programske jeziku Ruby, ki je
# enostavnejši za instalacijo, enostavnejši za razumevanje kode predvsem pa
# 100% prenosljiv med različnimi platformami.
#
# Preizkušeno deluje iz Windows Viste, XP in iz Ubuntu Linuxa, verjetno pa
# tudi iz vseh ostalih Windows okolij, vseh linux-ih unix-ih in vseh ostalih
# platformah, za katere dobite Ruby interpreter in podporo za OpenSSL.
# Več o Ruby-u si preberite na http://www.ruby-lang.org.
#
#
# Instalacija Ruby-ja.
#
# Windows: Instalacijsko datoteko, ki vsebuje vse potrebno,je najbolje
# prenesti iz http://rubyinstaller.org/ ali pa direktno iz:
# http://rubyforge.org/frs/download.php/62213/rubyinstaller-1.9.1-p243-preview2.exe
# 1.9.x verzije so že zadosti stabilne. Lahko pa uporabite tudi stabilno 1.8.6 verzijo
#
# Ubuntu Linux:
# apt-get install ruby
#
#
# Uporaba:
# V premenljivki msg popravite vsebino in vpišite vsebino vašega sporočila.
# Po možnosti brez čšž, ker so rezultati v nasprotnem primeru lahko nepričakovani.
# 
# Podatke o številkah kamor želite poslati sporočilo zapišite v tekstno datoteko.
# V vsako vrstico eno številko.
#
# Program poženete: ruby posljiSMS.rb ime_datoteke_z_naslovi
#
# Program obdela tudi odgovor strežnika in ga shrani v XML datoteko. Ime
# datotke je določeno z ID-jem sporočila. 
#
# Ne pozabite popraviti tudi takoj spodaj navedenega imena datoteke s
# certifikatom in gesla za privatni ključ. (CERT_FILE in CERT_PASS)
#
# V datoteko določeno s spremenljivko BLACK_FILE lahko vpišete spisek
# številk za katere ne želite, da se pošiljajo sporočila.
#
# Napisal Damjan Rems (d_rems {pri} yahoo pika com) 2009
###################################################################
require 'pomozniSMS'

CERT_FILE  = 'certifikat.pem'
CERT_PASS  = 'geslo'
SMS_HOST   = 'mostiscar.mobitel.si'
SMS_PATH   = '/pushdispatcher/dispatcher.asp'
SMS_PORT   = 443
BLACK_FILE = 'blacklist.txt'

#msg = 'Do konca tega sporocilca se bo nabralo precej znakov, pa vendar je to maksimalna dolzina poslanega sms sporocila.Torej maksimalna dolzina sporocila je tocno 160'
 msg = 'SMS sporocilo'
###################################################################
# Najprej malo kontrole
if ARGV.first.nil?
  puts 'Manjka ime vhodne datoteke s številkami'
  exit 1
end

unless File.exist?(ARGV.first)
  puts 'Vhodna datoteka s številkami ne obstaja'
  exit 1
end

if msg.size > 160
  puts 'Dolžina sporočila je lahko največ 160 znakov.'
  exit 1
end
###################################################################
# Preberi datoteko tistih, ki ne želijo prejemati SMS-jev
$blacklist = beri_blacklist()
$napakic, $poslanih, $blacklisted = 0, 0, 0
# v array numbers bo šel spisek številk
numbers = [] 
File.new(ARGV.first).readlines.each do |vrstica|
# Pošiljamo na 500 številk na enkrat
  if numbers.size > 499
    poslji_sporocilo(msg, numbers)
    numbers = []
  end
  ena = popravi_gsm_stevilko(vrstica)
  numbers << ena unless ena.nil?
end
poslji_sporocilo(msg, numbers) if numbers.size > 0
# Poročilo
puts "------------------------"
puts "Sporocilo: #{msg}"
puts
puts "Izvzete stevilke: #{$blacklisted}"
puts "Napakic:          #{$napakic}"
puts "OK poslanih:      #{$poslanih}"
