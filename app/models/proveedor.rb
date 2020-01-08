class Proveedor < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.ev}.proveedores"

  belongs_to :especie
  attr_accessor :totales, :observaciones, :observacion, :observaciones_mapa, :kml, :ejemplares, :ejemplar, :ejemplares_mapa

  # REVISADO: Las fotos de referencia de naturalista son una copia de las fotos de referencia de enciclovida
  def fotos_naturalista
    ficha = ficha_naturalista_api_nodejs
    return ficha unless ficha[:estatus]

    resultado = ficha[:ficha]['results'].first
    fotos = resultado['taxon_photos']
    {estatus: true, fotos: fotos}
  end

  def nombres_comunes_Y_fotos_naturalista
    ficha = ficha_naturalista_api # Se utilizará la versión sin nodejs, ya que esta no regresa los nombres comuúes
    return ficha unless ficha[:estatus]

    fotos = ficha[:ficha]['taxon_photos']
    nombres_comunes = ficha[:ficha]['taxon_names']
    # Pone en la primera posicion el deafult_name
    nombres_comunes.unshift(ficha[:ficha]['default_name']) if (ficha[:ficha]['default_name'].present? && ficha[:ficha]['default_name'].any?)
    {estatus: true, msg: {nc: nombres_comunes, ft: fotos}}
  end

  # REVISADO: Todos los nombres comunes de la ficha de naturalista
  def nombres_comunes_naturalista
    ficha = ficha_naturalista_api
    return ficha unless ficha[:estatus]

    nombres_comunes = ficha[:ficha]['taxon_names']
    # Pone en la primera posicion el deafult_name
    nombres_comunes.unshift(ficha[:ficha]['default_name']) if (ficha[:ficha]['default_name'].present? && ficha[:ficha]['default_name'].any?)
    {estatus: true, nombres_comunes: nombres_comunes}
  end

  # REVISADO: Consulta la ficha de naturalista por medio de su API nodejs
  def ficha_naturalista_api_nodejs
    # Si no existe naturalista_id, trato de buscar el taxon en su API y guardo el ID
    if naturalista_id.blank?
      resp = especie.ficha_naturalista_por_nombre
      return resp unless resp[:estatus]
    end

    begin
      resp = RestClient.get "#{CONFIG.inaturalist_api}/taxa/#{naturalista_id}"
      ficha = JSON.parse(resp)
    rescue => e
      return {estatus: false, msg: e}
    end

    return {estatus: false, msg: 'Tiene más de un resultado, solo debería ser uno por ser ficha'} unless ficha['total_results'] == 1
    return {estatus: true, ficha: ficha}
  end

  # REVISADO: Consulta la ficha por medio de su API web, algunas cosas no vienen en el API nodejs
  def ficha_naturalista_api
    # Si no existe naturalista_id, trato de buscar el taxon en su API y guardo el ID
    if naturalista_id.blank?
      resp = especie.ficha_naturalista_por_nombre
      return resp unless resp[:estatus]
    end

    begin
      resp = RestClient.get "#{CONFIG.naturalista_url}/taxa/#{naturalista_id}.json"
      ficha = JSON.parse(resp)
    rescue => e
      return {estatus: false, msg: e}
    end

    return {estatus: false, msg: 'Tiene más de un resultado, solo debería ser uno por ser ficha'} if ficha['error'] == 'No encontrado'
    return {estatus: true, ficha: ficha}
  end

  # REVISADO: Devuelve una lista de todas las URLS asociadas a los geodatos
  def geodatos
    geodatos = {}
    geodatos[:cuales] = []

    if geoserver_info.present?
      info = JSON.parse(geoserver_info)

      geodatos[:cuales] << 'geoserver'
      geodatos[:geoserver_url] = CONFIG.geoserver_url.to_s
      geodatos[:geoserver_descarga_url] = "#{CONFIG.geoserver_descarga_url}&layers=cnb:#{info['layers']}&styles=#{info['styles']}&bbox=#{info['bbox']}&transparent=true"
      geodatos[:geoserver_layer] = info['layers']
    end

    # Para las descargas del SNIB
    url = "#{CONFIG.site_url}especies/#{especie_id}/ejemplares-snib"

    resp = ejemplares_snib('.json')
    if resp[:estatus]
      geodatos[:cuales] << 'snib'
      geodatos[:snib_json] = "#{url}.json"
    end

    resp = ejemplares_snib('.kml')
    if resp[:estatus]
      geodatos[:cuales] << 'snib'
      geodatos[:snib_kml] = "#{url}.kml"
    end

    resp = ejemplares_snib('.kmz')
    if resp[:estatus]
      geodatos[:cuales] << 'snib'
      geodatos[:snib_kmz] = "#{url}.kmz"
    end

    resp = ejemplares_snib('.json', true)
    if resp[:estatus]
      geodatos[:cuales] << 'snib'
      geodatos[:snib_mapa_json] = "#{CONFIG.site_url}geodatos/#{especie_id}/#{resp[:ruta].split('/').last}"
    end

    # Para las descargas de naturalista
    url = "#{CONFIG.site_url}especies/#{especie_id}/observaciones-naturalista"

    resp = observaciones_naturalista('.json')
    if resp[:estatus]
      geodatos[:cuales] << 'naturalista'
      geodatos[:naturalista_json] = "#{url}.json"
    end

    resp = observaciones_naturalista('.kml')
    if resp[:estatus]
      geodatos[:cuales] << 'naturalista'
      geodatos[:naturalista_kml] = "#{url}.kml"
    end

    resp = observaciones_naturalista('.kmz')
    if resp[:estatus]
      geodatos[:cuales] << 'naturalista'
      geodatos[:naturalista_kmz] = "#{url}.kmz"
    end

    resp = observaciones_naturalista('.json', true)
    if resp[:estatus]
      geodatos[:cuales] << 'naturalista'
      geodatos[:naturalista_mapa_json] = "#{CONFIG.site_url}geodatos/#{especie_id}/#{resp[:ruta].split('/').last}"
    end

    geodatos[:cuales] = geodatos[:cuales].uniq
    geodatos
  end

  # REVISADO: Devuelve la informacion de una sola observacion,  de acuerdo al archivo previamente guardado del json
  def observacion_naturalista(observacion_id)
    resp = observaciones_naturalista('.json')
    return resp unless resp[:estatus]

    output = `grep :#{observacion_id}, #{resp[:ruta]}`
    return {estatus: false, msg: 'No encontro el ID'} unless output.present?
    obs = output.gsub('[{', '{').gsub('},', '}').gsub('}]', '}')

    begin
      resp.merge({observacion: JSON.parse(obs)})
    rescue
      {estatus: false, msg: 'Error al parsear el json'}
    end
  end

  # REVISADO: Devuelve las observaciones de naturalista, la respuesta depende del formato enviado, default es json
  def observaciones_naturalista(formato = '.json', mapa = false)
    carpeta = carpeta_geodatos

    nombre = if mapa
               carpeta.join("observaciones_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}_mapa")
             else
               carpeta.join("observaciones_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}")
             end

    archivo = "#{nombre}#{formato}"

    if File.exist?(archivo)
      {estatus: true, ruta: archivo}
    else
      {estatus: false, msg: 'No hay observaciones'}
    end
  end

  # REVISADO: Guarda las observaciones de naturalista
  def guarda_observaciones_naturalista

    # Para no generar geodatos arriba de familia
    return unless especie.apta_con_geodatos?

    # Para no guardar nada si el cache aun esta vigente
    return if especie.existe_cache?('observaciones_naturalista')

    # Pone el cache para no volverlo a consultar
    especie.escribe_cache('observaciones_naturalista', CONFIG.cache.observaciones_naturalista) if Rails.env.production?

    # Si no existe naturalista_id, trato de buscar el taxon en su API y guardo el ID
    if naturalista_id.blank?
      resp = especie.ficha_naturalista_por_nombre
      return resp unless resp[:estatus]
    end

    # Valida el paginado y los resultados
    self.observaciones = []
    self.observaciones_mapa = []

    # Limpia las observaciones y  las transforma a kml
    kml_naturalista(inicio: true)

    validacion = valida_observaciones_naturalista
    return validacion unless validacion[:estatus]

    # Para el paginado
    paginas = totales/CONFIG.inaturalist_por_pagina.to_i
    residuo = totales%200
    paginas+= 1 if residuo < 200 || paginas == 0

    # Si son mas de 50 paginas, entonces el elastic search truena del lado de inaturalist, ver como resolver despues (pasa mas en familia)
    #return {estatus: 'error', msg: 'Son mas de 50 paginas, truena el elastic search'} if paginas > 50

    if paginas > 1
      # Para consultar las demas paginas, si es que tiene mas de una
      for i in 2..paginas do
        validacion = valida_observaciones_naturalista({page: i})
        return validacion unless validacion[:estatus]
        break if i == 50
      end
    end

    # Cierra el kml
    kml_naturalista(fin: true)

    # Crea carpeta y archivo
    carpeta = carpeta_geodatos
    nombre = carpeta.join("observaciones_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}")

    archivo_observaciones = File.new("#{nombre}.json", 'w+')
    archivo_observaciones_mapa = File.new("#{nombre}_mapa.json", 'w+')
    archivo_observaciones_kml = File.new("#{nombre}.kml", 'w+')

    # Guarda el archivo en kml y kmz
    archivo_observaciones.puts observaciones.to_json.gsub('},{', "},\n{")
    archivo_observaciones_mapa.puts observaciones_mapa.to_json
    archivo_observaciones_kml.puts kml

    # Cierra los archivos
    archivo_observaciones.close
    archivo_observaciones_mapa.close
    archivo_observaciones_kml.close

    # Guarda el archivo en kmz
    kmz(nombre)

    puts "\n\nGuardo observaciones de naturalista #{especie_id}"
  end

  # REVISADO: Devuelve la informacion de un solo ejemplar,  de acuerdo al archivo previamente guardado del json
  def ejemplar_snib(ejemplar_id)
    resp = ejemplares_snib('.json')
    return resp unless resp[:estatus]

    output = `grep #{ejemplar_id} #{resp[:ruta]}`
    return {estatus: false, msg: 'No encontro el ID'} unless output.present?
    ej = output.gsub('[{', '{').gsub('"},', '"}').gsub('}]', '}')

    begin
      resp.merge({ejemplar: JSON.parse(ej)})
    rescue
      {estatus: false, msg: 'Error al parsear el json'}
    end
  end

  # REVISADO: Devuelve los ejemplares del snib en diferentes formatos, json (default), kml y kmz
  def ejemplares_snib(formato = '.json', mapa = false)
    carpeta = carpeta_geodatos

    nombre = if mapa
               carpeta.join("ejemplares_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}_mapa")
             else
               carpeta.join("ejemplares_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}")
             end

    archivo = "#{nombre}#{formato}"

    if File.exist?(archivo)
      {estatus: true, ruta: archivo}
    else
      {estatus: false, msg: 'No hay ejemplares en el SNIB'}
    end
  end

  # REVISADO: Guarda los distontos json asociados al SNIB
  def guarda_ejemplares_snib
    # Para no generar geodatos arriba de familia
    return unless especie.apta_con_geodatos?

    # Para no guardar nada si el cache aun esta vigente
    return if especie.existe_cache?('ejemplares_snib')

    # Pone el cache para no volverlo a consultar
    especie.escribe_cache('ejemplares_snib', CONFIG.cache.ejemplares_snib) if Rails.env.production?

    self.ejemplares = []
    self.ejemplares_mapa = []
    validacion = valida_ejemplares_snib
    return validacion unless validacion[:estatus]
    # Crea carpeta y archivo
    carpeta = carpeta_geodatos
    nombre = carpeta.join("ejemplares_#{especie.nombre_cientifico.limpiar.gsub(' ','_')}")
    archivo_ejemplares = File.new("#{nombre}.json", 'w+')
    archivo_ejemplares_mapa = File.new("#{nombre}_mapa.json", 'w+')
    archivo_ejemplares_kml = File.new("#{nombre}.kml", 'w+')

    # Guarda el archivo en kml y kmz
    # Esta linea hace mas facil el json del parseo y pone un salto de linea al final de cada ejemplar
    archivo_ejemplares.puts ejemplares.to_json.gsub('\\', '').gsub('"{', '{').gsub('}"', '}').gsub('},{', "},\n{")
    archivo_ejemplares_mapa.puts ejemplares_mapa.to_json
    archivo_ejemplares_kml.puts kml

    # Cierra los archivos
    archivo_ejemplares.close
    archivo_ejemplares_mapa.close
    archivo_ejemplares_kml.close

    # Guarda el archivo en kmz
    kmz(nombre)

    puts "\n\nGuardo ejemplares del snib #{especie_id}"
  end

  # Recupera sólo la cantidad de observaciones de Naturalista sobre una especie
  def numero_observaciones_naturalista

    numero_observs = {
        :casual => 0,
        :investigacion => 0
    }

    tipo_resultados = ['needs_id', 'research', 'casual']
    tipo_resultados.each do |tipo|

      # Invocar la API para consultar observaciones
      respuesta = api_naturalista_total_observaciones(params = { :tipo => "#{tipo}" })

      if respuesta[:estatus]

        resultado = respuesta[:msg]['results'][0]

        # Si no es de tipo research (científica), asignarlo a casual
        if tipo == 'research'
          numero_observs[:investigacion] = resultado['count']
        else
          numero_observs[:casual] = numero_observs[:casual] + resultado['count']
        end
      end
    end
    numero_observs
  end

  private

  # REVISADO: Crea o devuleve la capreta de los geodatos
  def carpeta_geodatos
    carpeta = Rails.root.join('public', 'geodatos', especie_id.to_s)
    FileUtils.mkpath(carpeta, :mode => 0755) unless File.exists?(carpeta)
    carpeta
  end

  # REVISADO: Solo los campos que ocupo en el mapa para no hacer muy grande la respuesta
  def limpia_observaciones_naturalista
    obs = Hash.new
    h = HTMLEntities.new  # Para codificar el html y no marque error en el KML

    # Los numere para poder armar los datos en el orden deseado
    obs[:id] = observacion['id']
    obs[:place_guess] = h.encode(observacion['place_guess'])
    obs[:observed_on] = observacion['observed_on'].gsub('-','/') if observacion['observed_on'].present?
    obs[:captive] = observacion['captive'] ? 'Organismo silvestre / naturalizado' : nil
    obs[:quality_grade] = I18n.t("quality_grade.#{observacion['quality_grade']}", default: observacion['quality_grade'])
    obs[:uri] = observacion['uri']

    if obs[:uri].present?
      obs[:uri] = obs[:uri].gsub('inaturalist.org','naturalista.mx').gsub('conabio.inaturalist.org', 'naturalista.mx').
          gsub('naturewatch.org.nz', 'naturalista.mx').gsub('conabio.naturalista.mx', 'naturalista.mx')

      relativa = obs[:uri].split('naturalista.mx').last
      obs[:uri] = "https://www.naturalista.mx#{relativa}"
    end

    obs[:longitude] = observacion['geojson']['coordinates'][0].to_f
    obs[:latitude] = observacion['geojson']['coordinates'][1].to_f

    observacion['photos'].each do |photo|
      obs[:thumb_url] = photo['url']
      obs[:attribution] = h.encode(photo['attribution'])
      break  # Guardo la primera foto
    end

    # Pone la observacion y las observaciones en el arreglo
    self.observacion = obs
    self.observaciones << observacion

    # Pone solo las coordenadas y el ID para el json del mapa, se necesita que sea mas ligero.
    self.observaciones_mapa << [observacion[:longitude], observacion[:latitude], observacion[:id], observacion[:quality_grade] == 'investigación' ? 1 : 2]
  end

  def api_naturalista_total_observaciones(params = { :tipo => "casual", :c_name => nil })

    begin # LLamada al servicio
      if params[:c_name].nil?
        rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.inaturalist_api}/observations/species_counts?taxon_id=#{naturalista_id}&quality_grade=#{params[:tipo]}&place_id=1", timeout: 20)
      else
        rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.inaturalist_api}/observations/species_counts?taxon_name=#{params[:c_name]}&quality_grade=#{params[:tipo]}&place_id=1", timeout: 20)
      end

      res = JSON.parse(rest_client)
    rescue => e
      return {estatus: false, msg: e}
    end

    total = res['total_results']

    unless res['results'].any?
      return {estatus: false, msg: 'No hay resultados que mostrar'}
    end

    if total.blank? || (total.present? && total <= 0)
      return {estatus: false, msg: 'No hay resultados que mostrar'}
    end

    return {estatus: true, msg: res}
  end

  # REVISADO: Valida que Naturalista tenga observaciones
  def valida_observaciones_naturalista(params = {})
    page = params[:page] || 1

    begin
      rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.inaturalist_api}/observations?taxon_id=#{naturalista_id}&geo=true&&per_page=#{CONFIG.inaturalist_por_pagina}&page=#{page}", timeout: 20)
      res = JSON.parse(rest_client)
    rescue => e
      return {estatus: false, msg: e}
    end

    if res.blank?
      borrar_geodata('observaciones_')
      return {estatus: false, msg: 'La respuesta del servicio esta vacia'}
    end

    self.totales = res['total_results'] if params.blank? && totales.blank?  # Para la primera pagina de naturalista
    resultados = res['results'] if res['results'].any?

    if totales.blank? || (totales.present? && totales <= 0)
      borrar_geodata('observaciones_')
      return {estatus: false, msg: 'No hay observaciones pero existe el array'}
    end

    if resultados.blank? || resultados.count == 0
      borrar_geodata('observaciones_')
      return {estatus: false, msg: 'No hay observaciones'}
    end

    resultados.each do |observacion|
      self.observacion = observacion
      limpia_observaciones_naturalista
      kml_naturalista(observacion: true)
    end

    {estatus: true}
  end

  # REVISADO: Transforma las observaciones de naturalista a kml
  def kml_naturalista(opc = {})

    if opc[:inicio]
      self.kml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      self.kml << "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n"
      self.kml << "<Document>\n"

      # Para las observaciones de grado cientifico, verde
      self.kml << "<Style id=\"Placemark_cientifico\">\n"
      self.kml << "<IconStyle>\n"
      self.kml << "<Icon>\n"
      self.kml << "<href>#{CONFIG.enciclovida_url}/assets/app/placemarks/verde.png</href>\n"
      self.kml << "</Icon>\n"
      self.kml << "</IconStyle>\n"
      self.kml << "</Style>\n"

      # Para las observaciones de grado casual, amarillo
      self.kml << "<Style id=\"Placemark_casual\">\n"
      self.kml << "<IconStyle>\n"
      self.kml << "<Icon>\n"
      self.kml << "<href>#{CONFIG.enciclovida_url}/assets/app/placemarks/amarillo.png</href>\n"
      self.kml << "</Icon>\n"
      self.kml << "</IconStyle>\n"
      self.kml << "</Style>\n"
    end

    if opc[:observacion]
      h = HTMLEntities.new  # Para codificar el html y no marque error en el KML
      nombre_cientifico = h.encode(especie.nombre_cientifico)
      nombre_comun = h.encode(especie.nom_com_prin(true))
      nombre = nombre_comun.present? ? "<b>#{nombre_comun}</b> <i>(#{nombre_cientifico})</i>" : "<i><b>#{nombre_cientifico}</b></i>"

      self.kml << "<Placemark>\n"
      self.kml << "<description>\n"
      self.kml << "<![CDATA[\n"
      self.kml << "<div>\n"
      self.kml << "<h4>\n"
      self.kml << "<a href=\"#{CONFIG.enciclovida_url}/especies/#{especie.id}\">#{nombre}</a>\n"
      self.kml << "</h4>\n"

      self.kml << "<div><img src=\"#{observacion[:thumb_url]}\"/></div>\n"

      self.kml << '<dl>'
      self.kml << "<dt>Atribución</dt> <dd>#{observacion[:attribution]}</dd>\n"
      self.kml << "<dt>Ubicación</dt> <dd>#{observacion[:place_guess]}</dd>\n"
      self.kml << "<dt>Fecha</dt> <dd>#{observacion[:observed_on]}</dd>\n"
      self.kml << "<dt>#{observacion[:captive]}</dt> <dd> </dd>\n"
      self.kml << "<dt>Grado de calidad</dt> <dd>#{observacion[:quality_grade]}</dd>\n"
      self.kml << '</dl>'

      self.kml << "<span><text>Ver la </text><a href=\"#{observacion[:uri]}\">observación en NaturaLista</a></span>\n"

      self.kml << "</div>\n"
      self.kml << "]]>\n"
      self.kml << "</description>\n"

      if observacion[:quality_grade] == 'investigación'
        self.kml << '<styleUrl>#Placemark_cientifico</styleUrl>'
      else
        self.kml << '<styleUrl>#Placemark_casual</styleUrl>'
      end

      self.kml << "<Point>\n<coordinates>\n#{observacion[:longitude]},#{observacion[:latitude]}\n</coordinates>\n</Point>\n"
      self.kml << "</Placemark>\n"
    end

    if opc[:fin]
      self.kml << "</Document>\n"
      self.kml << '</kml>'
    end
  end

  # REVISADO: Solo las coordenadas y el ID
  def limpia_ejemplares_snib
    # Para ver si es de aver aves el ejemplar
    aves = %w(averaves ebird)
    coleccion = ejemplar['coleccion'].downcase
    es_averaves = false
    valor_coleccion = 1

    coleccion.split(' ').each do |col|
      break if es_averaves

      if aves.include?(col)
        es_averaves = true
      end
    end

    # Para ver si la locacion no es de campo, tiene mas preferencia
    if ejemplar['probablelocnodecampo'].try(:estandariza) == 'si'
      valor_coleccion = 4
    elsif es_averaves
      valor_coleccion = 2
    elsif ejemplar['ejemplarfosil'].try(:estandariza) == 'si'
      valor_coleccion = 3
    end

    # Pone solo las coordenadas y el ID para el json del mapa, se necesita que sea mas ligero.
    self.ejemplares_mapa << [ejemplar['longitud'], ejemplar['latitud'], ejemplar['idejemplar'], valor_coleccion]
  end

  # REVISADO: Valida los ejemplares del SNIB
  def valida_ejemplares_snib
    begin
      Rails.logger.debug "[DEBUG] - #{CONFIG.geoportal_url}/#{especie.root.nombre_cientifico.downcase}/#{especie.scat.catalogo_id}?apiKey=enciclovida"
      rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.geoportal_url}/#{especie.root.nombre_cientifico.estandariza}/#{especie.scat.catalogo_id}?apiKey=enciclovida", timeout: 3)
      resultados = JSON.parse(rest_client)
    rescue => e
      return {estatus: false, msg: e}
    end

    if resultados.blank?
      borrar_geodata('ejemplares_')
      return {estatus: false, msg: 'La respuesta del servicio esta vacia'}
    end

    self.totales = resultados.count if totales.blank?  # Para la primera pagina de naturalista

    if totales.blank? || (totales.present? && totales <= 0)
      borrar_geodata('ejemplares_')
      return {estatus: false, msg: 'No hay ejemplares'}
    end

    self.ejemplares_mapa = []

    # Asigna los ejemplares
    self.ejemplares = resultados

    resultados.each do |ejemplar|
      self.ejemplar = ejemplar
      limpia_ejemplares_snib
    end

    # Exporta a kml los ejemplares
    kml_snib

    {estatus: true}
  end

  # REVISADO: Transforma los ejemplares del SNIB a kml
  def kml_snib
    h = HTMLEntities.new  # Para codificar el html y no marque error en el KML
    nombre_cientifico = h.encode(especie.nombre_cientifico)
    nombre_comun = h.encode(especie.nom_com_prin(true))
    nombre = nombre_comun.present? ? "<b>#{nombre_comun}</b> <i>(#{nombre_cientifico})</i>" : "<i><b>#{nombre_cientifico}</b></i>"

    self.kml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    self.kml << "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n"
    self.kml << "<Document>\n"
    self.kml << "<Style id=\"normalPlacemark\">\n"
    self.kml << "<IconStyle>\n"
    self.kml << "<Icon>\n"
    self.kml << "<href>#{CONFIG.enciclovida_url}/assets/app/placemarks/rojo.png</href>\n"
    self.kml << "</Icon>\n"
    self.kml << "</IconStyle>\n"
    self.kml << "</Style>\n"

    ejemplares.each do |ejemplar|
      self.kml << "<Placemark>\n"
      self.kml << "<description>\n"
      self.kml << "<![CDATA[\n"
      self.kml << "<div>\n"
      self.kml << "<h4>\n"
      self.kml << "<a href=\"#{CONFIG.enciclovida_url}/especies/#{especie.id}\">#{nombre}</a>\n"
      self.kml << "</h4>\n"
      self.kml << "<dl>\n"

      self.kml << "<dt>Localidad</dt> <dd>#{ejemplar['localidad']}</dd>\n"
      self.kml << "<dt>Municipio</dt> <dd>#{ejemplar['municipiomapa']}</dd>\n"
      self.kml << "<dt>Estado</dt> <dd>#{ejemplar['estadomapa']}</dd>\n"
      self.kml << "<dt>País</dt> <dd>#{ejemplar['paismapa']}</dd>\n"
      self.kml << "<dt>Fecha</dt> <dd>#{ejemplar['fechacolecta']}</dd>\n"
      self.kml << "<dt>Nombre del colector</dt> <dd>#{ejemplar['colector']}</dd>\n"
      self.kml << "<dt>Colección</dt> <dd>#{ejemplar['coleccion']}</dd>\n"
      self.kml << "<dt>Institución</dt> <dd>#{ejemplar['institucion']}</dd>\n"
      self.kml << "<dt>País de la colección</dt> <dd>#{ejemplar['paiscoleccion']}</dd>\n"

      if ejemplar['proyectourl'].present?
        self.kml << "<dt>Proyecto:</dt> <dd><a href=\"#{ejemplar['proyectourl']}\">#{ejemplar['proyecto'] || 'ver'}</a></dd>\n"
      else
        self.kml << "<dt>Proyecto:</dt> <dd>#{ejemplar['proyecto']}</dd>\n"
      end

      self.kml << "</dl>\n"

      self.kml << "<span><text>Más información: </text><a href=\"http://#{ejemplar['urlejemplar']}\">consultar SNIB</a></span>\n"

      self.kml << "</div>\n"
      self.kml << "]]>\n"
      self.kml << "</description>\n"
      self.kml << '<styleUrl>#normalPlacemark</styleUrl>'
      self.kml << "<Point>\n<coordinates>\n#{ejemplar['longitud']},#{ejemplar['latitud']}\n</coordinates>\n</Point>\n"
      self.kml << "</Placemark>\n"
    end

    self.kml << "</Document>\n"
    self.kml << '</kml>'
  end

  # REVISADO: Comprime el kml a kmz
  def kmz(nombre)
    archvo_zip = "#{nombre}.zip"
    system "zip -j #{archvo_zip} #{nombre}.kml"
    File.rename(archvo_zip, "#{nombre}.kmz")
  end

  # REVISADO: Borra el json, kml, kmz del taxon en cuestion, ya sea observaciones o ejemplares
  def borrar_geodata(tipo)
    ruta = Rails.root.join('public', 'geodatos', especie_id.to_s, "#{tipo}*")
    archivos = Dir.glob(ruta)

    archivos.each do |a|
      File.delete(a)
    end
  end

  def photo_type(url)
    return 'FlickrPhoto' if url.include?("staticflickr\.com") || url.include?("static\.flickr\.com")
    return 'EolPhoto' if url.include? "media\.eol\.org"
    return 'NaturalistaPhoto' if url.include? "static\.inaturalist\.org"
    return 'WikimediaCommonsPhoto' if url.include? "upload\.wikimedia\.org"
  end

  def taxon_photos(datos, usuario)
    photos = []
    datos['taxon_photos'].each do |pho| #Guarda todas las fotos asociadas del taxon
      next unless pho['photo']['native_photo_id'].present?
      next unless pho['photo']['thumb_url'].present?
      next unless photo_type(pho['photo']['thumb_url']).present?

      local_photo = Photo.where(:native_photo_id => pho['photo']['native_photo_id'], :type => photo_type(pho['photo']['thumb_url']))
      photo = local_photo.count == 1 ? local_photo.first : Photo.new #Crea o actualiza la foto

      photo.usuario_id = usuario
      photo.native_photo_id = pho['photo']['native_photo_id']
      photo.square_url = pho['photo']['square_url']
      photo.thumb_url = pho['photo']['thumb_url']
      photo.small_url = pho['photo']['small_url']
      photo.medium_url = pho['photo']['medium_url']
      photo.large_url = pho['photo']['large_url']
      #photo.original_url = pho['photo']['original_url']
      photo.created_at = pho['photo']['created_at']
      photo.updated_at = pho['photo']['updated_at']
      photo.native_page_url = pho['photo']['native_page_url']
      photo.native_username = pho['photo']['native_username']
      photo.native_realname = pho['photo']['native_realname']
      photo.license = pho['photo']['license']
      photo.type = photo_type(pho['photo']['thumb_url'])
      photos << photo
    end
    photos
  end

end
