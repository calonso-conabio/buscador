module CacheServices

  # REVISADO: Actualiza todos los servicios concernientes a un taxon, se empaqueto para que no estuviera en Especie
  def servicios
    guarda_redis_servicio

    if Rails.env.production?
      guarda_estadisticas_servicio
      guarda_observaciones_naturalista_servicio
      guarda_ejemplares_snib_servicio
      guarda_pez_servicios
      # estadisticas_naturalista_servicio
      # estadisticas_conabio_servicio
      # estadisticas_wikipedia_servicio
      # estadisticas_eol_servicio
      # estadisticas_tropicos_service_servicio
      # estadisticas_maccaulay_servicio
      # estadisticas_SNIB_servicio
      # estadisticas_mapas_distribucion_servicio
    end
  end

  def guarda_estadisticas_servicio
    if Rails.env.production?
      delay(queue: 'estadisticas').guarda_estadisticas
    else
      guarda_estadisticas
    end
  end

  def guarda_estadisticas
    cuantas_especies_inferiores(estadistica_id: 2)
    cuantas_especies_inferiores(estadistica_id: 3)  # Servicio para poner el numero totales de especies o inferiores del taxon
    cuantas_especies_inferiores({estadistica_id: 22, validas: true})  # Servicio para poner el numero totales de especies validas del taxon
    cuantas_especies_inferiores({estadistica_id: 23, validas: true})  # Servicio para poner el numero totales de especies o inferiores validas del taxon
  end

  # REVISADO: Guarda los datos más importantes en el redis
  def guarda_redis_servicio(opc={})
    if Rails.env.production?
      delay(queue: 'redis').guarda_redis(opc)
    else
      guarda_redis(opc)
    end
  end

  # REVISADO: Guarda la información asociada al pez
  def guarda_pez_servicios
    if Rails.env.production?
      pez.delay(queue: 'peces').save if pez
    else
      pez.save if pez
    end
  end

  # REVISADO: Guarda las observaciones desde la pagina de naturalista
  def guarda_observaciones_naturalista_servicio
    if !existe_cache?('observaciones_naturalista')
      if p = proveedor
        if Rails.env.production?
          p.delay(queue: 'observaciones_naturalista').guarda_observaciones_naturalista
        else
          p.guarda_observaciones_naturalista
        end
      end
    end
  end

  # REVISADO: Guarda los ejemplares del SNIB
  def guarda_ejemplares_snib_servicio
    if !existe_cache?('ejemplares_snib')
      if p = proveedor
        if Rails.env.production?
          p.delay(queue: 'ejemplares_snib').guarda_ejemplares_snib
        else
          p.guarda_ejemplares_snib
        end
      end
    end
  end


  # REVISADO: Es un metodo que no depende del la tabla proveedor, puesto que consulta naturalista sin el ID
  def ficha_naturalista_por_nombre
    return if existe_cache?('ficha_naturalista')
    self.jres = { estatus: false, msg: 'No hay resultados' }  # Mensaje default

    begin
      respuesta = RestClient.get "#{CONFIG.inaturalist_api}/taxa?q=#{URI.escape(nombre_cientifico.limpiar)}"
      resultados = JSON.parse(respuesta)
    rescue => e
      self.jres = jres.merge({msg: e})
      return
    end

    # Nos aseguramos que coincide el nombre
    return if resultados['total_results'].blank? || resultados['total_results'] == 0

    resultados['results'].each do |t|
      next unless t['ancestor_ids'].present?
      next unless t['name'].downcase == nombre_cientifico.limpiar.downcase

      # Es un reino
      reino_naturalista = t['ancestor_ids'][1]
      next unless reino_naturalista.present?
      reino_enciclovida = root_id

      # Me aseguro que el reino coincida
      next if !((reino_naturalista == reino_enciclovida) || # Reino animalia
          (reino_naturalista == 47126 && reino_enciclovida == 2) || # Reino plantae
          (reino_naturalista == 47170 && reino_enciclovida == 4) || # Reino fungi
          ([48222, 47686].include?(reino_naturalista) && reino_enciclovida == 5)) # Reino protoctista o chromista en naturalista

      if p = proveedor
        p.naturalista_id = t['id']
        p.save if p.changed?
      else
        self.proveedor = Proveedor.create({ naturalista_id: t['id'], especie_id: id })
      end

      self.jres = jres.merge({ estatus: true, ficha: t, msg: nil })
      escribe_cache('ficha_naturalista', CONFIG.cache.ficha_naturalista) if Rails.env.production?
      return

    end  # End resultados
  end

  # REVISADO: Escribe un cache
  def escribe_cache(recurso, tiempo = 1.day)
    Rails.cache.write("#{recurso}_#{id}", :expires_in => eval(tiempo).to_f, :created_at => Time.now.to_f)
  end

  # REVISADO: Verifica que el cache exista
  def existe_cache?(recurso)
    if Rails.cache.exist?("#{recurso}_#{id}")
      cache = Rails.cache.read("#{recurso}_#{id}")

      r = cache[:created_at] && cache[:expires_in]
      return false unless r

      begin
        (cache[:created_at] + cache[:expires_in]) > Time.now.to_f
      rescue
        false
      end

    else
      false
    end
  end

  # REVISADO: Borra un cache
  def borra_cache(recurso)
    Rails.cache.delete("#{recurso}_#{id}")
  end

  # REVISADO: Gurada los nombres comunes y cientifico en redis
  def guarda_redis(opc={})
    # Le suma la visita del usuario para que no truene corriendolo como un proceso separado
    suma_visita

    # Pone en nil las variables para guardar los servicios y no consultarlos de nuevo
    self.x_foto_principal = nil
    self.x_nombre_comun_principal = nil
    self.x_lengua = nil
    self.x_fotos_totales = 0  # Para poner cero si no tiene fotos
    self.x_nombres_comunes = nil
    self.x_nombres_comunes_todos = []

    if opc[:loader].present? # Guarda en el loader que especifico
      loader = Soulmate::Loader.new(opc[:loader])
    else # Guarda en la cataegoria taxonomica correspondiente
      categoria = I18n.transliterate(categoria_taxonomica.nombre_categoria_taxonomica).gsub(' ','_')
      loader = Soulmate::Loader.new(categoria)

      if !Rails.env.development_mac?
        borra_fuzzy_match
        FUZZY_NOM_CIEN.put(nombre_cientifico.strip, id)
      end
    end

    # Borra los actuales
    borra_redis(loader)

    # Guarda el redis con el nombre cientifico y los demas servicios
    loader.add(asigna_redis(opc.merge({consumir_servicios: true})))

    # Guarda el redis con todos los nombres comunes
    num_nombre = 0

    x_nombres_comunes_todos.each do |nombres|
      lengua = nombres.keys.first

      nombres.values.flatten.each_with_index do |nombre|
        num_nombre+= 1
        id_referencia = nombre_comun_a_id_referencia(num_nombre)
        nombre_obj = NombreComun.new({id: id_referencia, nombre_comun: nombre, lengua: lengua})
        loader.add(asigna_redis(opc.merge({nombre_comun: nombre_obj})))

        if !Rails.env.development_mac?
          FUZZY_NOM_COM.put(nombre, id_referencia) if opc[:loader].nil?
        end

      end
    end
  end

  def estadisticas_naturalista_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_naturalista')

    if Rails.env.production?
      # Para no guardar nada si el cache aun esta vigente
      escribe_cache('estadisticas_naturalista', CONFIG.cache.estadisticas.estadisticas_naturalista) if Rails.env.production?
      delay(queue: 'estadisticas_naturalista').estadisticas_naturalista
    else
      estadisticas_naturalista
    end
  end

  def estadisticas_conabio_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_conabio')

    if Rails.env.production?
      escribe_cache('estadisticas_conabio', CONFIG.cache.estadisticas.estadisticas_conabio) if Rails.env.production?
      delay(queue: 'estadisticas_conabio').estadisticas_conabio
    else
      estadisticas_conabio
    end
  end

  def estadisticas_wikipedia_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_wikipedia')

    if Rails.env.production?
      escribe_cache('estadisticas_wikipedia', CONFIG.cache.estadisticas.estadisticas_wikipedia) if Rails.env.production?
      delay(queue: 'estadisticas_wikipedia').estadisticas_wikipedia
    else
      estadisticas_wikipedia
    end
  end

  def estadisticas_eol_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_eol')

    if Rails.env.production?
      escribe_cache('estadisticas_eol', CONFIG.cache.estadisticas.estadisticas_eol) if Rails.env.production?
      delay(queue: 'estadisticas_eol').estadisticas_eol
    else
      estadisticas_eol
    end
  end

  def estadisticas_tropicos_service_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_tropicos_service')

    if Rails.env.production?
      escribe_cache('estadisticas_tropicos_service', CONFIG.cache.estadisticas.estadisticas_tropicos_service) if Rails.env.production?
      delay(queue: 'estadisticas_tropicos_service').estadisticas_tropicos_service
    else
      estadisticas_tropicos_service
    end
  end

  def estadisticas_maccaulay_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_maccaulay')

    if Rails.env.production?
      escribe_cache('estadisticas_maccaulay', CONFIG.cache.estadisticas.estadisticas_maccaulay) if Rails.env.production?
      delay(queue: 'estadisticas_maccaulay').estadisticas_maccaulay
    else
      estadisticas_maccaulay
    end
  end

  def estadisticas_SNIB_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_SNIB')

    if Rails.env.production?
      escribe_cache('estadisticas_SNIB', CONFIG.cache.estadisticas.estadisticas_SNIB) if Rails.env.production?
      delay(queue: 'estadisticas_SNIB').estadisticas_SNIB
    else
      estadisticas_SNIB
    end
  end

  def estadisticas_mapas_distribucion_servicio
    # No hacer nada si aún es vigente el caché
    return if existe_cache?('estadisticas_mapas_distribucion')

    if Rails.env.production?
      escribe_cache('estadisticas_mapas_distribucion', CONFIG.cache.estadisticas.estadisticas_mapas_distribucion) if Rails.env.production?
      delay(queue: 'estadisticas_mapas_distribucion').estadisticas_mapas_distribucion
    else
      estadisticas_mapas_distribucion
    end
  end

  # Datos estadísticos
  def estadisticas_naturalista(guardar = true)

    # Respuesta de la función
    res = {
        :total_nombres_comunes => 0,
        :total_fotos => 0,
        :total_observaciones_investigacion => 0,
        :total_observaciones_casual => 0
    }

    # Acceder a tabla proveedor
    if proveedor_n = proveedor
      sleep(3.seconds)  # Esperar X segundo(s) antes de llamar al servicio

      # Para los nombres comunes de naturalista
      proveedor_n.nombres_comunes_naturalista
      self.resp = proveedor_n.resp

      if resp[:estatus]
        resp_nombres = resp[:nombres_comunes]
        resp_nombres = resp_nombres.delete_if { |h| h["lexicon"] == "Scientific Names" }
        res[:total_nombres_comunes] = resp_nombres.length
      end

      # Para las fotos de naturalista
      proveedor_n.fotos_naturalista
      self.resp = proveedor_n.resp

      if resp[:estatus]
        res[:total_fotos] = resp[:fotos].length
      end

      if especie_o_inferior?
        # Obtener el total de observaciones:

        # Opción 1: consultando directamente el servicio de naturalista (No sirve por ahora...)
        # tipo_observaciones = proveedor_n.numero_observaciones_naturalista
        # ID: 19. Grado de investigación
        # res[:total_observaciones_investigacion] = tipo_observaciones[:investigacion]
        # ID: 20. Grado casual
        # res[:total_observaciones_casual] = tipo_observaciones[:casual]

        # Opción 2: consultando a través de geodatos[:naturalista_mapa_json]
        if los_geodatos = proveedor_n.geodatos # verificar que contenga geodatos
          if los_geodatos.key?(:naturalista_mapa_json) && !los_geodatos[:naturalista_mapa_json].blank? # verificar que contenga la llave naturalista_mapa_json
            url_geodatos = los_geodatos[:naturalista_mapa_json]
            consulta = invoca_url_geodatos(url_geodatos)

            if consulta['estatus'] # buscar el total y tipos de observaciones existentes en un archivo JSON
              json = consulta['msg']
              observaciones = json.map { |x| x[3]}
              observaciones.each { |obs| obs == 1 ? res[:total_observaciones_investigacion] += 1 : res[:total_observaciones_casual] += 1 }
            end
          end
        end
      end
    end

    if guardar
      estd = especie_estadisticas
      escribe_estadistica(estd, 4, res[:total_nombres_comunes])
      escribe_estadistica(estd, 6, res[:total_fotos])
      escribe_estadistica(estd, 19, res[:total_observaciones_investigacion]) if especie_o_inferior?
      escribe_estadistica(estd, 20, res[:total_observaciones_casual]) if especie_o_inferior?
    end
    res
  end

  def estadisticas_conabio(guardar = true)

    # Respuesta de la función
    res = {
        :total_nombres_comunes => 0,
        :total_fotos => 0,
        :total_fichas => 0
    }

    # ID: 5 Nombres comunes de CONABIO
    res[:total_nombres_comunes] = nombres_comunes.count

    # ID: 7 Fotos en el Banco de Imágenes de CONABIO
    res[:total_fotos] = fotos_bdi[:fotos].count

    # ID: 11 Fichas revisadas de CONABIO -> Sólo aparecerá si tiene ficha asociada (0 o 1)
    if cat = scat
      res[:total_fichas] = Fichas::Taxon.where(IdCat: cat.catalogo_id).count
    else
      # No se encuentra en el catálogo, por tanto no tiene ninguna ficha asociada
      res[:total_fichas] = 0
    end

    # ID: 12 Fichas en revisión de CONABIO ( no existe campo)
    if guardar
      estd = especie_estadisticas
      escribe_estadistica(estd, 5, res[:total_nombres_comunes])
      escribe_estadistica(estd, 7, res[:total_fotos])
      escribe_estadistica(estd, 11, res[:total_fichas])
    end
    res
  end

  def estadisticas_wikipedia(guardar = true)

    # Respuesta de la función
    res = {
        :ficha_espaniol => 0,
        :ficha_ingles => 0
    }
    # ID: 9 Fotos en Wikimedia (Ya no)
    begin
      # ID: 15 Fichas de Wikipedia-español
      res[:ficha_espaniol] = TaxonDescribers::WikipediaEs.describe(self).blank? ?  0 : 1
      # ID: 16 Fichas de Wikipedia-ingles
      res[:ficha_ingles] = TaxonDescribers::Wikipedia.describe(self).blank? ? 0 : 1

      if guardar
        estd = especie_estadisticas
        escribe_estadistica(estd, 15, res[:ficha_espaniol])
        escribe_estadistica(estd, 16, res[:ficha_ingles])
      end

    rescue StandardError => msg
      Rails.logger.debug msg
      borra_cache('estadisticas_wikipedia')
    end

    res
  end

  def estadisticas_eol(guardar = true)

    # Respuesta de la función
    res = {
        :ficha_espaniol => 0,
        :ficha_ingles => 0
    }

    begin
      # ID: 13 Fichas de EOL-español
      res[:ficha_espaniol] = TaxonDescribers::EolEs.describe(self).blank? ?  0 :  1
      # ID: 14 Fichas de EOL-ingles
      res[:ficha_ingles] = TaxonDescribers::Eol.describe(self).blank? ?  0 :  1

      if guardar
        estd = especie_estadisticas
        escribe_estadistica(estd, 13, res[:ficha_espaniol])
        escribe_estadistica(estd, 14, res[:ficha_ingles])
      end

    rescue StandardError => msg
      Rails.logger.debug msg
      borra_cache('estadisticas_eol')
    end

    res
  end

  def estadisticas_tropicos_service(guardar = true)

    # Respuesta de la función
    res = {
        :total_fotos => 0
    }

    # Crear instancia de servicio trópicos:
    ts_req = Tropicos_Service.new
    respuesta = get_tropico_id

    begin

      if respuesta[:estatus]
        # Si existe el tropico_id, recuperar las imágenes
        tropico_id = respuesta[:id]
        fotos = ts_req.get_media(tropico_id)
        fotos[0]["Error"].present? ? res[:total_fotos] = 0 : res[:total_fotos] =  ts_req.get_media(tropico_id).count
      else
        res[:total_fotos] =  0
      end

      estd = especie_estadisticas
      escribe_estadistica(estd, 24, res[:total_fotos]) if guardar

    rescue => e
      Rails.logger.debug e.message
      Rails.logger.debug "ERROR: ID #{id}"
      borra_cache('estadisticas_tropicos_service')
    end

    res
  end

  def estadisticas_maccaulay(guardar = true)

    # Respuesta de la función
    res = {}

    begin
      taxonNC = nombre_cientifico
      res[:total_fotos] = itera_servicio_maccaulay(taxonNC, "photo")
      res[:total_videos] = itera_servicio_maccaulay(taxonNC, "video")
      res[:total_audios] = itera_servicio_maccaulay(taxonNC, "audio")

      if guardar
        estd = especie_estadisticas
        escribe_estadistica(estd, 25, res[:total_fotos])
        escribe_estadistica(estd, 26, res[:total_videos])
        escribe_estadistica(estd, 27, res[:total_audios])
      end

    rescue
      borra_cache("estadisticas_maccaulay")
    end

    res
  end

  # SNIB: Sistema Nacional de Información sobre Biodiversidad de México
  def estadisticas_SNIB(guardar = true)

    return unless especie_o_inferior?

    # Respuesta de la función
    res = {
        :ejemplares_snib => 0
        #:ejemplares_snib_averaves => 0
    }

    # LLamada al servicio para obtener los resultados SNIB
    resultados_snib = recupera_ejemplares_snib(self.scat.catalogo_id)

    # Verificar el estatus de la llamada al servicio
    # En teorìa, se puede acceder al arreglo de 'resultados'
    if resultados_snib.first.include?('nregistros')
      res[:ejemplares_snib] = resultados_snib.first['nregistros']
    end

    # Ahora, buscar los de eBird
    # buscar = ['eBird eBird', 'aVerAves aVerAves']
    # res[:ejemplares_snib_averaves] = 0
    # Itera todos los ejemplares y busca los de aVerAves
    # resultados_snib['resultados'].each do |ejemplar|
    #   if buscar.include? (ejemplar['coleccion'])
    #     res[:ejemplares_snib_averaves] += 1
    #   end
    # end

    if guardar
      estd = especie_estadisticas
      escribe_estadistica(estd, 17, res[:ejemplares_snib])
      # escribe_estadistica(estd, 18, res[:ejemplares_snib_averaves])
    end
    res
  end

  def estadisticas_mapas_distribucion(guardar = true)
    return unless especie_o_inferior?

    # Respuesta de la función
    res = {:mapas_distribucion => 0}
    # ID: 21 Mapas de distribución
    if p = proveedor
      pg = p.geodatos
      res[:mapas_distribucion] = pg[:cuales].include?('geoserver') ?  1 : 0
    end
    estd = especie_estadisticas
    escribe_estadistica(estd, 21, res[:mapas_distribucion]) if guardar
    res
  end

  def itera_estadisticas_restantes
    Especie.all.each do |especie_x|
      next unless especie_x.especie_o_inferior?
      especie_x.genera_estadisticas_directo
    end
  end

  def self.itera_especies
    # Obtener todas las especies a iterar
    especies_todas = Especie.all

    especies_todas.each do |especie_x|
      # Eliminar el caché si tiene
      especie_x.borra_cache('estadisticas_naturalista')
      especie_x.borra_cache('estadisticas_conabio')
      especie_x.borra_cache('estadisticas_wikipedia')
      especie_x.borra_cache('estadisticas_eol')
      especie_x.borra_cache('estadisticas_tropicos_service')
      especie_x.borra_cache('estadisticas_maccaulay')
      especie_x.borra_cache('estadisticas_SNIB')
      especie_x.borra_cache('estadisticas_mapas_distribucion')
      especie_x.genera_estadisticas
    end
  end

  def genera_estadisticas_directo
    # Invocar las estadisticas de naturalista
    borra_cache('estadisticas_SNIB')
  end

  def genera_estadisticas
    # Invocar las estadisticas de naturalista
    estadisticas_naturalista_servicio
    estadisticas_conabio_servicio
    estadisticas_wikipedia_servicio
    estadisticas_eol_servicio
    estadisticas_tropicos_service_servicio
    estadisticas_maccaulay_servicio
    estadisticas_SNIB_servicio
    estadisticas_mapas_distribucion_servicio
  end

  private

  # Función para invocar la url geodatos/ y extraer el json con las observaciones
  def invoca_url_geodatos(geodatos_especie)
    resultados = {}
    begin
      # LLamada al servicio de enciclovida para obtener el JSON
      rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.enciclovida_url}#{geodatos_especie}", timeout: 20)
      resultados['estatus'] = true
      resultados['msg'] = JSON.parse(rest_client)
    rescue
      resultados['estatus'] = false
      resultados['msg'] = "Hubo un error al invocar la URL: #{geodatos_especie} "
    end
    resultados
  end

  def get_tropico_id()

    # Crear instancia de servicio trópicos:
    ts_req = Tropicos_Service.new

    # Para saber si tiene proveedor asociado
    if prov = proveedor
      # Verificar si tiene ya el tropico_id (si se consultó anteriormente)
      if tropico_id = prov.tropico_id
        return {'estatus': true, id: tropico_id}
      else
        # No existe aún el tropico_id, buscarlo
        name_id = ts_req.get_id_name(nombre_cientifico)
        unless name_id[0][:msg].present?
          prov.update(tropico_id: name_id[0]['NameId'])
          return {estatus: true, id: name_id[0]['NameId']}
        end
      end
    else
      # No existe aún la especie en proveedores ni el tropico_id, buscarlo invocando el servicio:
      name_id = ts_req.get_id_name(nombre_cientifico)
      unless name_id[0][:msg].present?
        Proveedor.create(especie_id: id, tropico_id: name_id[0]['NameId'])
        return {'estatus': true, id: name_id[0]['NameId']}
      end
    end
    return {estatus: false}
  end

  # LLama a enciclovida.mx para accder a los ejemplares SNIB de cada especie
  def recupera_ejemplares_snib(especie_id)
    resultados = {}
    begin
      # LLamada al servicio de enciclovida para obtener el JSON
      rest_client = RestClient::Request.execute(method: :get, url: "#{CONFIG.enciclovida_api}/especie/snib/ejemplares/conteo?idnombrecatvalido=#{especie_id}", timeout: 20)
      resultados = JSON.parse(rest_client)
    rescue
      resultados['estatus'] = "error"
    end
    resultados
  end

  # Funciòn para llamar a maccaulay, hace las llamadas suficientes para extraer el total de archivos existentes sobre una especie (una llamada por cada pàgina)
  def itera_servicio_maccaulay(nombre_especie, tipo)
    servicio = MacaulayService.new
    total = 0
    total_por_pagina = 1000
    (1..100).each do | i |
      if i > 1 && %w(photo audio video).include?(tipo) && total < (total_por_pagina * (i - 1))
        break # No tiene caso buscar cuando ya no hay mas resultadose  en las demàs pàginas
      end
      archivo = servicio.dameMedia_nc(nombre_especie, tipo, i, total_por_pagina)
      if archivo == nil && i == 1
        total = 0
        break
      else

        # Si se regresó un mensaje, es porque por alguna razón no existieron fotos
        if archivo[0][:msg].present?
          break
        else
          if archivo.count == 0
            break
          else
            total = total + archivo.count
          end
        end
      end
      Rails.logger.debug "Hasta ahora hay: #{total}"
    end
    total
  end



  # Recibe el apuntador a la tabla y escribe el dato en ella segùn el id de la estadìstica
  def escribe_estadistica(estd, estd_id, dato)
    if estadistica = estd.where(estadistica_id: estd_id).first
      # Si ya existe, actualizar si cambiò
      estadistica.conteo = dato
      estadistica.save if estadistica.changed?
    else
      # Si no, crearla
      estadistica = estd.new
      estadistica.conteo = dato
      estadistica.estadistica_id = estd_id
      estadistica.save
    end
  end

  # REVISADO: Guarda fotos y nombres comunes de dbi, catalogos y naturalista
  def guarda_fotos_nombres_servicios
    ficha_naturalista_por_nombre if !proveedor || proveedor.naturalista_id.blank?  # Para encontrar el naturalista_id si no existe el proveedor
    guarda_nombres_comunes_todos
    guarda_fotos_todas
  end

  # REVISADO: Guarda en adicionales las fotos
  def guarda_fotos_todas
    dame_fotos_todas

    if x_foto_principal.present?
      a = adicional ? adicional.reload : Adicional.new(especie_id: id)
      a.foto_principal = x_foto_principal

      if a.changed?
        a.save
        reload
      end
    end
  end

  # REVISADO: Guarda los nombres comunes en adicionales
  def guarda_nombres_comunes_todos
    dame_nombres_comunes_todos

    if x_nombre_comun_principal.present?
      a = adicional ? adicional : Adicional.new(especie_id: id)
      a.nombres_comunes = x_nombres_comunes.encode('UTF-8', {invalid: :replace, undef: :replace, replace: ''})
      a.nombre_comun_principal = x_nombre_comun_principal.force_encoding("UTF-8")

      if a.changed?
        a.save
        reload
      end
    end
  end

  # REVISADO: Asigna el redis correspondiente
  def asigna_redis(opc={})
    datos = {}
    datos[:data] = {}

    guarda_fotos_nombres_servicios if opc[:consumir_servicios]
    visitas = especie_estadisticas.visitas

    # Asigna si viene la peticion de nombre comun
    if nc = opc[:nombre_comun]
      datos[:id] = nc.id
      datos[:term] = I18n.transliterate(nc.nombre_comun.limpia)
      datos[:data][:nombre_comun] = nc.nombre_comun
      datos[:data][:id] = id
      datos[:data][:lengua] = nc.lengua

      # Para el score dependiendo la lengua
      lengua = nc.lengua.estandariza
      index = Adicional:: LENGUAS_ACEPTADAS.reverse.index(lengua) || 0
      datos[:score] = index*visitas

    else  # Asigna si viene la peticion de nombre_cientifico
      datos[:id] = id
      datos[:term] = I18n.transliterate(nombre_cientifico.limpia)
      datos[:data][:nombre_comun] = x_nombre_comun_principal
      datos[:data][:id] = id
      datos[:data][:lengua] = x_lengua
      datos[:score] = Adicional::LENGUAS_ACEPTADAS.length*visitas
    end

    if opc[:foto_principal].present?
      datos[:data][:foto] = opc[:foto_principal]
    else
      datos[:data][:foto] = x_square_url  # Foto square_url
    end

    datos[:data][:publico] = 0
    datos[:data][:nombre_cientifico] = nombre_cientifico.limpia
    datos[:data][:estatus] = Especie::ESTATUS_VALOR[estatus]
    datos[:data][:autoridad] = nombre_autoridad.try(:limpia)

    # Para poner si es publico o no
    if cat = scat
      datos[:data][:publico] = cat.publico
    end

    # Caracteristicas de riesgo y conservacion, ambiente y distribucion
    cons_amb_dist = {}

    caracteristicas = nom_cites_iucn_ambiente_prioritaria({iucn_ws: true})
    caracteristicas[:grupo1] << tipo_distribucion

    # Paso de la muerte para que solo itere sobre un hash
    caracteristicas.map { |k,v| v.reduce({}, :merge) }.reduce({}, :merge).each do |nombre, valores|
      next unless valores.any?

      valores.each do |valor|
        cons_amb_dist[valor.estandariza] = valor
      end
    end

    datos[:data][:cons_amb_dist] = cons_amb_dist

    # Para saber cuantas fotos tiene
    datos[:data][:fotos] = x_fotos_totales

    # Para saber si tiene algun mapa
    if p = proveedor
      datos[:data][:geodatos] = p.geodatos[:cuales]
    end

    datos.stringify_keys
  end

  # REVISADO: Es el ID del nombre comun que va vinculado al nombre cientifico
  def nombre_comun_a_id_referencia(num_nombre)
    # El 1 inicial es para identificarlo, despues se forza el ID a 6 digitos y el numero de nombre comun a 3 digitos
    "1#{id.to_s.rjust(6,'0')}#{num_nombre.to_s.rjust(3,'0')}".to_i
  end

  # REVISADO: borra todos los nombres comunes y el cnetifico del redis, para posteriormente volver a generarlo
  def borra_redis(loader)
    # Borra el del nombre cientifico
    nombre_cient_data = {id: id}.stringify_keys
    loader.remove(nombre_cient_data)

    # Borra los nombre comunes
    100.times do |i|
      id_referencia = nombre_comun_a_id_referencia(i+1)
      nombre_com_data = {id: id_referencia}.stringify_keys
      loader.remove(nombre_com_data)
    end
  end

  # REVISADO: Borra el fuzzy match de los nombres comunes y nombre cientifico
  def borra_fuzzy_match
    return if Rails.env.development_mac?
    # Borra el nombre cientifico
    FUZZY_NOM_CIEN.delete(id)

    # Borra los nombre comunes
    100.times do |i|
      id_referencia = nombre_comun_a_id_referencia(i+1)
      FUZZY_NOM_COM.delete(id_referencia)
    end
  end

  # REVISADO: Regresa el numero de especies
  def cuantas_especies(opc = {})
    scope = descendants.solo_especies
    scope = scope.where(estatus: 2) if opc[:validas]
    scope.count
  end

  # REVISADO: Regresa el numero de especies e inferiores
  def cuantas_especies_e_inferiores(opc = {})
    scope = descendants.especies_e_inferiores
    scope = scope.where(estatus: 2) if opc[:validas]
    scope.count
  end

  # REVISADO: Pone el conteo de las especies o inferiores de un taxon en la tabla estadisticas
  def cuantas_especies_inferiores(opc = {})
    return unless opc[:estadistica_id].present?
    Rails.logger.debug "\n\nGuardo estadisticas_cuantas_especies_inferiores_#{opc[:estadistica_id]} - #{id} ..."
    escribe_cache("estadisticas_cuantas_especies_inferiores_#{opc[:estadistica_id]}", CONFIG.cache.estadisticas.cuantas_especies_inferiores) if Rails.env.production?

    conteo = case opc[:estadistica_id]
             when 2, 22
               cuantas_especies(opc)
             when 3, 23
               cuantas_especies_e_inferiores(opc)
             else
               false
             end

    return unless conteo

    if estadistica = especie_estadisticas.where(estadistica_id: opc[:estadistica_id]).first
      estadistica.conteo = conteo
      estadistica.save if estadistica.changed?
      return
    end

    # Quiere decir que no existia la estadistica
    estadistica = especie_estadisticas.new
    estadistica.conteo = conteo
    estadistica.estadistica_id = opc[:estadistica_id]
    estadistica.save
  end

  # REVISADO: Suma la visita de una ficha en la tabla estadisticas
  def suma_visita
    Rails.logger.debug "\n\nGuardo conteo de visitas #{id} ..."

    if estadistica = especie_estadisticas.where(estadistica_id: 1).first
      estadistica.conteo+= 1
      estadistica.save
      return
    end

    # Quiere decir que no existia la estadistica
    estadistica = especie_estadisticas.new
    estadistica.estadistica_id = 1
    estadistica.conteo = 1
    estadistica.save
  end

  #Métodos a borrar, se utilizaran y se eliminaran posteriormente
  def dame_carpeta_geodatos
    carpeta = Rails.root.join('public', 'geodatos', id.to_s)
    FileUtils.mkpath(carpeta, :mode => 0755) unless File.exists?(carpeta)
    carpeta
  end

  def retrae_observaciones_naturalista
    return unless apta_con_geodatos?
    return unless p = proveedor
    archivo = dame_carpeta_geodatos.join("observaciones_#{nombre_cientifico.limpiar.gsub(' ','_')}")
    return if File.exists?(archivo)
    guarda_observaciones_naturalista
  end

end