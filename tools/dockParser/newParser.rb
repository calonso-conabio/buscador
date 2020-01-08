require 'docx'
require 'set'
require 'rubygems'
require 'trollop'
# Variables a utilizar en el codigo
parrafos = Array.new
parrafosSinEspacio = Array.new
estado = ""
buscar = Array.new
p = ""
respuestas = Array.new

doc = Docx::Document.open('/home/sergiocg/test.docx')
doc = Dir.glob('/home/sergiocg/Documents/Fichas/Aves/*.docx')
doc.each do |d|
  puts d
  doc = Docx::Document.open(d)
  # Se insertan los parrafos del archivo docx en un Array llamado parrafos
  doc.paragraphs.each do |p|
    parrafos.append(p.to_s)
  end

# Se inicia un parceo del de los arrays para poder manipular secciones del documento
  parrafos.each_with_index { |k, i|
    if parrafos[i+1].class == NilClass
      break
    else
      if parrafos[i+1].empty? == true
        if estado.empty? == false
          parrafosSinEspacio.append(estado)
          estado = String.new
        else
          parrafosSinEspacio.append(parrafos[i])
        end
      else
        estado.concat(" ",parrafos[i+1])
      end
    end
  }

  # Se buscan ciertos campos de y se insertan en un array llamado buscar
  parrafosSinEspacio.each do |m|
    if m.include?"Descripción de la especie" or
        m.include?"Distribución original" or
        m.include?"Distribución como exótica en el Mundo Estatus: Exótica presente en México"
      buscar.append(m)
    end
  end

  # Se buscan ciertos campos de la parte de respuestas y se insertan en un array llamado respuestas
  parrafosSinEspacio.each do |m|
    if m.include?"Relación con taxones cercanos invasores" or m.include?"Reporte de invasora" or m.include?"Vector de otras especies invasoras" or
        m.include?"Impactos sanitarios" or m.include?"Impactos económicos y sociales" or m.include?"Impactos al ecosistema" or m.include?"Impactos a la biodiversidad"
      n = m
      if n.include?"Muy Alto:"
        respuestas.append(n.partition("Muy Alto:").last)
      elsif n.include?"Alto:"
        respuestas.append(n.partition("Alto:").last)
      elsif n.include?"Medio:"
        respuestas.append(n.partition("Medio:").last)
      elsif n.include?"Bajo:"
        respuestas.append(n.partition("Bajo:").last)
      elsif n.include?"Se desconoce."
        respuestas.append(n.partition("Se desconoce.").last)
      elsif n.include?"No:"
        respuestas.append(n.partition("No:").last)
      end
    end
  end
  # Las siguientes variables almacenan la información a buscar se especifica
  # el valor que contiene cada una

  parrafos[2] # nombre cientifico
  parrafosSinEspacio[3] # primera descripcion va a fespecies.taxon.resumenEspecie
  buscar # primeras busquedas
  respuestas # seccion respuestas
  parrafosSinEspacio.last.split("\n") #referencias refernciabibliografica

  # Serecupera la lista de paises para realizar busquedas se
  # almacenan en un array llamado p
  tempPaises = buscar[1].gsub(/\(.*?\)/, '')
  f = tempPaises.gsub('Distribución original', '')
  paises  = f.split(',')

  OPTS = Trollop::options do
    banner <<-EOS
  Usage:
    rails r tools/dockParser/newParser.rb

  where [options] are:
    EOS
    opt :debug, 'Print debug statements', :type => :boolean, :short => '-d'
  end

  paisesFinal = []
  # Aqui empiesa a consultar la base de datos
  v = Validacion.new
  v.nombre_cientifico = parrafos[2]
  v.encuentra_por_nombre

  if v.validacion[:estatus]
    e = Especie.find(v.validacion[:taxon][:IdNombre])
    puts e.scat[:IDCAT]
    f = Fichas::Taxon.where('IdCAT = ?', e.scat[:IDCAT]).first
    # f = Fichas::Taxon.where( "IdCAT = ?" , "1370REPTI")

    # Si encontro algo en fespecies.taxon
    if f
      puts "Valor de F #{f.inspect}"
    else
      f1 = Fichas::Taxon.new
      # Base Fespecies tabla taxon
      puts f1.inspect
      f1.IdCAT = e.scat[:IDCAT]
      f1.resumenEspecie = parrafosSinEspacio[3]
      f1.descEspecie = buscar[0]
      # fespecies tabla distribuciones
      di = f1.distribuciones.new
      di.comoExoticaMundial = buscar.last

      # ciclo que busca los ide de los paises
      paises.each do |i|
        p = Fichas::Pais.select(:paisId).where('nombrepais  = ?', i.strip).to_a
        puts "error algo pasa"
        puts p[0].inspect
        if p[0].nil?
          puts 'aqui ay un nil'
        else
          paisesFinal.append(p[0][:paisId])
        end
      end

      d1 = di.relDistribucionesPaises.new(paisesFinal.map {|pais| {'paisId'=>pais,'tipopais' =>0} })
      # seccionde preguntas id = 59,42,62 [65,66],64,63
      # pregunta 1
      p1 = f1.observacionescaracs.new
      p1.idpregunta = 59
      p1.infoadicional = respuestas[1]
      # pregunta 2
      p2 = f1.observacionescaracs.new
      p2.idpregunta = 42
      p2.infoadicional = respuestas[2]
      # pregunta 3
      p3 = f1.observacionescaracs.new
      p3.idpregunta = 62
      p3.infoadicional = respuestas[3]
      # pregunta 4
      p4 = f1.observacionescaracs.new
      p4.idpregunta = 65
      p4.infoadicional = respuestas[4]
      # pregunta 4 bis
      p4b= f1.observacionescaracs.new
      p4b.idpregunta = 66
      p4b.infoadicional = respuestas[4]
      # pregunta 5
      p5 = f1.observacionescaracs.new
      p5.idpregunta = 64
      p5.infoadicional = respuestas[5]
      # pregunta 6
      p6 = f1.observacionescaracs.new
      p6.idpregunta = 63
      p6.infoadicional = respuestas[6]
      f1.save
    end
  end
end
