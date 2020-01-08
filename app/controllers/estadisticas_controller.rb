class EstadisticasController < ApplicationController

  layout 'estadisticas'
  before_action :get_statistics, :filtros_iniciales, only: [:show]

  def show
    # Por si no coincidio nada
    @taxones = Especie.none
    # El tipo de filtro que se va a utilizar
    resultados_avanzada_estadistica
  end

  # Obtiene todas las estadisticas existentes > 0
  def get_statistics
    @estadisticas = {}
    #Extraer el nombre e id de todas las estadisticas existentes para buscar el total de todas las especies
    Estadistica.all.each do |estadistica|
      # Saltar estadísticas que ya no se usan
      next if Estadistica::ESTADISTICAS_QUE_NO.index(estadistica.id)
      @estadisticas[estadistica.id] = {
          'nombre_estadistica': estadistica.descripcion_estadistica,
          'conteo': EspecieEstadistica.all.where("estadistica_id = #{estadistica.id} AND conteo > 0").size
      }
    end
    @totales_estadisticas = build_json_to_statics(@estadisticas)
    @estadisticas
  end

  def filtros_estadisticas
    @resultados = {}
    @resultados = get_statistics
    render json: build_json_to_statics(@resultados)
  end

  private

  # Los filtros de la busqueda avanzada y de los resultados
  def filtros_iniciales
    @reinos = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_REINOS)
    @animales = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_ANIMALES)
    @plantas = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_PLANTAS)
    @nom_cites_iucn_todos = Catalogo.nom_cites_iucn_todos
    @distribuciones = TipoDistribucion.distribuciones(I18n.locale.to_s == 'es-cientifico')
  end

  def resultados_avanzada_estadistica

    busqueda = BusquedaAvanzada.new
    busqueda.params = params
    busqueda.es_cientifico = I18n.locale.to_s == 'es-cientifico' ? true : false
    busqueda.original_url = request.original_url
    busqueda.formato = request.format.symbol.to_s
    busqueda.resultados_avanzada


    @totales = busqueda.totales
    # No se requiere
    @taxones = busqueda.taxones

    response.headers['x-total-entries'] = @totales.to_s if @totales > 0
    @totales_estadisticas = build_json_to_statics(busqueda.estadisticas)

    respond_to do |format|
        filtros_iniciales
        set_filtros
        format.html { render action: 'show' }
    end
  end


  def set_filtros
    @setParams = {}

    params.each do |k,v|
      # Evitamos valores vacios
      next unless v.present?

      case k
        when 'id', 'nombre', 'por_pagina', 'tipoResultado'
          @setParams[k] = v
        when 'edo_cons', 'dist', 'prior', 'estatus', 'showEstadisticas'
          if @setParams[k].present?
            @setParams[k] << v.map{ |x| x.parameterize if x.present?}
          else
            @setParams[k] = v.map{ |x| x.parameterize if x.present?}
          end
        else
          next
      end
    end
  end

  # Método para construir un JSON que pueda interpretar el generador de gráficas estadisticas.js
  def build_json_to_statics(datos)

    # Árbol de estadísticas
    estadisticas = []

    multimedia = agrega_hijo(estadisticas, "Multimedia")
    fichas = agrega_hijo(estadisticas, "Fichas")
    nombres_c = agrega_hijo(estadisticas, "Nombres comunes")
    obser = agrega_hijo(estadisticas, "Observaciones")
    ejemp = agrega_hijo(estadisticas, "Ejemplares")
    mapas = agrega_hijo(estadisticas, "Mapas")
    n_espe = agrega_hijo(estadisticas, "Número especies")
    visit = agrega_hijo(estadisticas, "Visitas")
    otros = agrega_hijo(estadisticas, "Otros")

    datos.each do |dato|
      estd = dato[1][:nombre_estadistica]
      if estd.include?('Fotos') || estd.include?('Audio') || estd.include?('Videos')
        if estd.include?('Fotos')
          foto = agrega_hijo(multimedia[:children], "Fotos")
          agrega_valor(foto, dato[1])
        elsif estd.include?('Audio')
          audio = agrega_hijo(multimedia[:children], "Audios")
          agrega_valor(audio, dato[1])
        elsif estd.include?('Videos')
          video = agrega_hijo(multimedia[:children], "Videos")
          agrega_valor(video, dato[1])
        end
      elsif estd.include?('Fichas')
        agrega_valor(fichas, dato[1])
      elsif estd.include?('Nombres comunes')
        agrega_valor(nombres_c, dato[1])
      elsif estd.include?('Observaciones')
        agrega_valor(obser, dato[1])
      elsif estd.include?('Ejemplares')
        agrega_valor(ejemp, dato[1])
      elsif estd.include?('Mapas')
        agrega_valor(mapas, dato[1])
      elsif estd.include?('Número')
        agrega_valor(n_espe, dato[1])
      elsif estd.include?('Visitas')
        agrega_valor(visit, dato[1])
      else
        agrega_valor(otros, dato[1])
      end
    end

    root_est = {'name': "Estadísticas CONABIO", 'children': estadisticas}
    root_est.to_json
  end

  # Método para construir un json aceptable para el generador de gráficas: Agrega subcomponentes a componente
  def agrega_hijo(padre, name)
    # Si ya existe, solo devolverlo
    if pdre = padre.find {|x| x[:name] == name}
      hijo = pdre
    else
      # Si no existe el nuevo hijo, agregarlo
      hijo = {'name': name, 'children': []}
      padre.append(hijo)
    end
    hijo
  end

  # Método para construir un json aceptable para el generador de gráficas: Agrega el valor de cada componente
  def agrega_valor(padre, dato)
    # Si el nombre del dato, contiene un '-', dividirlo
    if dato[:nombre_estadistica].include?('-')
      nombres = dato[:nombre_estadistica].split("-", 2)
      valor = agrega_hijo(padre[:children], nombres[0])
      valor[:children].append("name": nombres[1], "size": dato[:conteo])
    else
      padre[:children].append("name": (dato[:nombre_estadistica].gsub("#{padre[:name]} ","").gsub("de ","").gsub("en ","").gsub("el ","")), "size": dato[:conteo])
    end
    padre
  end

end