require 'rubygems'
require 'trollop'

OPTS = Trollop::options do
  banner <<-EOS
Exporta todas los nombres cientificos, nombres comunes de catalogos y nombres comunes de naturalista a redis,
adicionalmente guarda la foto principal y el nombre comun principal


*** Este script solo es necesario correrlo una vez, ya que la ficha actualiza el taxon

Usage:

  rails r tools/guarda_redis.rb -d

where [options] are:
  EOS
  opt :debug, 'Print debug statements', :type => :boolean, :short => '-d'
end


def guarda_redis
  puts 'Procesando los nombres cientificos...' if OPTS[:debug]
  ultima_corrida = false

  Especie.find_each do |t|
    # Para saltarse a algun taxon en especifico, por si se quedo truco el redis
    ultima_corrida = true if t.id == 6001318
    next unless ultima_corrida

    #Especie.limit(100).each do |t|
    puts "#{t.id}-#{t.nombre_cientifico}" if OPTS[:debug]
    t.guarda_redis
  end
end

def testUno
  puts "TestUno"
end

start_time = Time.now

#guarda_redis
testUno

puts "Termino en #{Time.now - start_time} seg" if OPTS[:debug]