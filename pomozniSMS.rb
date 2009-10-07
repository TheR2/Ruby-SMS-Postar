#coding: utf-8
###################################################################
# Nekaj pomoznih metod, ki pridejo prav pri posiljanju SMS-ov.
#
# Napisal Damjan Rems (d_rems {pri} yahoo pika com) 2009
###################################################################
require 'net/https'
require 'rexml/document'

###################################################################
# To sem snel nekje iz Neta. Kako najkrajše do generiranega naključnega
# gesla ali v našem primeru ID-ja.
#
# Parametri:
# length : Integer : Dolžina id-ja
#
# Rezultat: String :  Naključen niz znakov dolg zahtevano dolžino.
###################################################################
CHARSET = ('a'..'z').to_a + ('0'..'9').to_a + ('A'..'Z').to_a
def get_id(length)
  (1..length).map{|i| CHARSET[rand(62)]}.join
end

###################################################################
# Sestavi XML sporočilo. To je čisti minimum potreben za pošiljanje
# SMS sporočila na n naslovov.
#
# Parametri:
# msg : Sporočilo, ki bo poslano
# numbers : Array : Spisek telefonskih številk
#
# Rezultat: String : XML sporocilo pripravljeno za pošiljanje.
###################################################################
def sestavi_xml(msg, numbers)
  xml    = REXML::Document.new('<Packet version="1.2"></Packet>')
  header = xml.root.add_element 'Header'
  header.add_element('Content').add_text(msg)
  header.add_element('ID').add_text( get_id(30) )
# Dodaj body in potem še Item za vsako telefonsko številko posebej.
  body = xml.root.add_element 'Body'
  numbers.each do |num|
    i = body.add_element('Item')
    i.add_attribute('Type','SMS')
    i.add_element('Phone_no').add_text(num)
  end
  xml.to_s
end

###################################################################
# Obdelaj rezultate pošiljanja sporočil. Rezultat shrani v XML datoteko,
# ki ima naziv po ID-ju sporočila. ID je naključen niz znakov dolg 30 mest
# in se lahko uporabi za poznejše ponovno ugotavljanje statusa na Mobitelu.
#
# Parametri:
# odgovor : String : XML odgovor, ki smo ga prejeli od strežnika
###################################################################
def obdelaj_odgovor(odgovor)
  xml = REXML::Document.new(odgovor)
  id  = xml.elements['Packet/Header/ID'].text
  xml.elements.each('Packet/Body/Item') do | item |
# Ce je Content==Message sent" je OK. Drugace je napaka.
    if item.elements["Content"].text == 'Message sent'
      $poslanih += 1
    else
      puts "#{item.elements['Phone_no'].text} : #{item.elements['Content'].text}"
      $napakic += 1
    end
  end
# Zapiši odgovor v datoteko
  File.open("#{id}.xml",'w') { |f| f.write(odgovor) }
end

###################################################################
# Pošlje sporočilo na host. Najprej vzpostavi komunikacijo, prebere certifikat,
# dešifrira privatni ključ, sestavi xml sporočilo in pošlje sporočilo na strežnik.
# Na koncu kliče še metodo za obdelavo odgovora.
#
# Parametri:
# msg : Sporočilo, ki bo poslano
# numbers : Array : Spisek telefonskih številk
###################################################################
def poslji_sporocilo(msg, numbers)
  https             = Net::HTTP.new(SMS_HOST, SMS_PORT)
  https.use_ssl     = true
  https.cert        = OpenSSL::X509::Certificate.new( File.read(CERT_FILE) )
  https.key         = OpenSSL::PKey::RSA.new( File.read( CERT_FILE), CERT_PASS )
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE

  puts "Posiljam #{numbers.size} sporocil ....."
  sporocilo = sestavi_xml(msg, numbers)
  odgovor   = https.post(SMS_PATH, sporocilo)
  obdelaj_odgovor(odgovor.body)
end

###################################################################
# Popravi številko v zapis dolg 9 mest. Preveri tudi ali je številka na spisku 
# tistih, ki ne želijo prejemati SMS sporočil.
#
# Parametri:
# num : Številka za popravit
#
# Rezultat : Številka, ki ustreza Mobitelovi specifikaciji ali nil, če je na 
# spisku tistih, ki ne želijo prejemati SMS sporočil.
###################################################################
def popravi_gsm_stevilko(num)
# Če jih je več, so ločene z vejico. Uporabi samo prvo številko
  c = num.chomp.split(",").first
  unless c.nil?
# Briši razne nepotrebne znake
    c = c.gsub(' ','').gsub('-','').gsub('(','').gsub('/','').gsub(')','')
    c = c.gsub('+386','')            # briši +386
    c = '0' + c unless c[0,1] == '0' # ni vodilne 0
    c = c[0,9] if c.size > 9
  end
# Preveri če je na blacklisti
  unless $blacklist[c].nil?
    $blacklisted += 1
    puts "Številka #{c} je na spisku izvzetih številk"
    c = nil
  end
  c
end

###################################################################
# Prebere datoteko s spiskom številk tistih, ki ne želijo prejemati SMS sporočil.
#
# Parametri:
# filename : Ime datoteke s spiskom številk.
#
# Rezultat : Hash : Številke iz spiska.
###################################################################
def beri_blacklist(filename)
  list = {}
  if File.exist?(filename)
    File.new(filename).readlines.each { |l| list[l.chomp.strip] = 1 }
  end
  list
end
