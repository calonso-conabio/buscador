class BusquedasController < ApplicationController

  before_action only: :resultados, if: -> {params[:busqueda] == 'avanzada'} do
    @no_render_busqueda_basica = true
  end

  before_action only: :avanzada do
    @no_render_busqueda_basica = true
  end

  skip_before_action :set_locale, only: [:cat_tax_asociadas]
  layout false, :only => [:cat_tax_asociadas]

  # REVISADO: Los filtros de la busqueda avanzada
  def avanzada
    filtros_iniciales
  end

  # REVISADO: Los resultados de busqueda basica o avanzada
  def resultados
    # Por si no coincidio nada
    @taxones = Especie.none

    if params[:busqueda] == 'basica'
      resultados_basica
    elsif params[:busqueda] == 'avanzada'
      resultados_avanzada
    else  # Default, error
      respond_to do |format|
        format.html { redirect_to  '/inicio/error', :notice => 'Búsqueda incorrecta por favor inténtalo de nuevo.' }
        format.json { render json: {taxa: []} }
      end
    end  # Fin if busqueda
  end

  # Servicio que por medio del nombre comun extrae todos los nombres comunes asociados al taxon (servicio para alejandro molina)
  def nombres_comunes
    select = "NombreComun.datos_basicos(['nombres_comunes.id'])"
    select_count = 'NombreComun.datos_count'

    if params[:exact].present? && params[:exact].to_i == 1
      condiciones = ".caso_sensitivo('nombre_comun', \"#{params[:q].limpia_sql}\").
                where('especies.id IS NOT NULL')"
    else
      condiciones = ".caso_insensitivo('nombre_comun', \"#{params[:q].limpia_sql}\").
                where('especies.id IS NOT NULL')"
    end

    sql = select << condiciones + ".distinct.order('nombre_comun ASC')"
    sql_count = select_count << condiciones

    query = eval(sql).to_sql
    consulta = Bases.distinct_limpio query
    totales = eval(sql_count)[0].cuantos

    @data = {}
    @data[:termino] = params[:q]
    @data[:numero_resultados] = totales
    @data[:resultados] = []

    if totales > 0
      consulta << ' ORDER BY nombre_comun ASC'
      nombres_comunes = NombreComun.find_by_sql(consulta)

      # Para no repetir los taxones
      especie_ids = []

      nombres_comunes.each do |nombre_comun|
        nombre_comun.especies.each do |especie|

          next if especie_ids.include?(especie.id)
          especie_ids << especie.id
          nombres = especie.nombres_comunes.map(&:nombre_comun)
          @data[:resultados] << {nombre_comun_coincidio: nombre_comun.nombre_comun, taxon: especie.nombre_cientifico, nombres_comunes: nombres}
        end
      end

    end

    render json: @data.to_json
  end

  # TODO: falta ver el funcionamiento del checklist; ¿talves contempalr la tabla plana?
  def checklist(sin_filtros=false)
    if sin_filtros
      #Sin no tengo filtros, dibujo el checklist tal y caul como lo recibo (render )
    else
      padres = {}
      @taxones.each do |taxon|
        taxon.arbol.split('/').each do |p|
          padres[p.to_i]=''
        end
      end
      #Aquí entro al query sin filtros (a pesar de que mi búsqueda fue CON filtros) pq ya tengo todos los papás, ahora necesito sus datos y ordenarlos por campo arbol
      @taxones = Especie.datos_arbol_sin_filtros.where("especies.id in (#{padres.keys.join(',')})").order('arbol')
    end
  end

  def dame_listas
    respond_to do |format|
      format.html { render :json => dameListas(@listas) }
    end
  end

  # REVISADO: Las categoras asociadas de acuerdo al taxon que escogio
  def cat_tax_asociadas
    especie = Especie.find(params[:id])
    @categorias = especie.cat_tax_asociadas
  end

  def tabs
  end


  private

  # REVISADO: Los filtros de la busqueda avanzada y de los resultados
  def filtros_iniciales
    @reinos = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_REINOS)

    animales = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_ANIMALES)
    @animales = []
    animales.each do |animal|
      if index = Busqueda::GRUPOS_ANIMALES.index(animal.nombre_cientifico)
        @animales[index] = animal
      end
    end

    plantas = Especie.select_grupos_iconicos.where(nombre_cientifico: Busqueda::GRUPOS_PLANTAS)
    @plantas = []
    plantas.each do |planta|
      if index = Busqueda::GRUPOS_PLANTAS.index(planta.nombre_cientifico)
        @plantas[index] = planta
      end
    end

    @nom_cites_iucn_todos = Catalogo.nom_cites_iucn_todos

    @distribuciones = TipoDistribucion.distribuciones(I18n.locale.to_s == 'es-cientifico')

    @prioritarias = Catalogo.prioritarias
  end

  # TODO: falta ver el funcionamiento del checklist; ¿talves contempalr la tabla plana?
  def resultados_basica
    pagina = (params[:pagina] || 1).to_i

    busqueda = BusquedaBasica.new
    busqueda.params = params
    busqueda.es_cientifico = I18n.locale.to_s == 'es-cientifico' ? true : false
    busqueda.original_url = request.original_url
    busqueda.formato = request.format.symbol.to_s
    busqueda.resultados_basica

    @totales = busqueda.totales
    @por_categoria = busqueda.por_categoria || []
    @taxones = busqueda.taxones
    @fuzzy_match = busqueda.fuzzy_match
    arbol = false

    response.headers['x-total-entries'] = @totales.to_s if @taxones.present?

    respond_to do |format|

      if @taxones.any? && arbol
        # Po si requieren que se genere el checklis
        @arboles = []

        @taxones.each do | taxon|
          # Primero hallo nombre comunes, mape unicamente el campo nombre_comun, le pego el nombre común principal (si tiene), saco los únicos y los ordeno alfabéticamente non-case
          nombres_comunes = (taxon.nombres_comunes.map(&:nombre_comun) << taxon.adicional.nombre_comun_principal).uniq.sort_by{|w| [I18n.transliterate(w.downcase), w] unless !(w.present?)}
          # Jalo unicamente los ancestros del taxón en cuestión
          arbolito = Especie.datos_arbol_para_json.where("especies.id = (#{taxon.id})")[0].arbol.split('/').join(',')

          # Género el árbol para cada uno de los ancestros recién obtenidos en la linea anterior de código ^
          @arboles << (Especie.datos_arbol_para_json_2.where("especies.id in (#{arbolito})" ).order('arbol') << {"distancia" => taxon.try("distancia") || 0} << {"nombres_comunes" => nombres_comunes.compact} )
        end

        format.json { render json: @arboles.to_json }

      elsif params[:solo_categoria].present? && @taxones.length > 0 && pagina == 1  # Imprime el inicio de un TAB
        format.html { render :partial => 'busquedas/resultados' }
        format.json { render json: {taxa: @taxones} }
        format.xlsx { descargar_taxa_excel }
      elsif pagina > 1 && @taxones.length > 0  # Imprime un set de resultados con el scrolling
        # Despliega el paginado del TAB que tiene todos
        format.html { render :partial => 'busquedas/_resultados' }
        format.json { render json: {taxa: @taxones} }
      elsif (@taxones.length == 0 || @totales == 0) && pagina > 1  # Cuando no hay resultados en la busqueda o el scrolling
        format.html { render plain: '' }
        format.json { render json: {taxa: []} }
      else  # Ojo si no entro a ningun condicional desplegará el render normal (resultados.html.erb)
        format.html { render action: 'resultados' }
        format.json { render json: { taxa: @taxones, x_total_entries: @totales, por_categoria: @por_categoria.present? ? @por_categoria : [] } }
        format.xlsx { descargar_taxa_excel }
      end
    end  # end respond_to
  end

  # TODO: falta ver el funcionamiento del checklist; ¿talves contempalr la tabla plana?
  def resultados_avanzada
    pagina = (params[:pagina] || 1).to_i

    busqueda = BusquedaAvanzada.new
    busqueda.params = params
    busqueda.es_cientifico = I18n.locale.to_s == 'es-cientifico' ? true : false
    busqueda.original_url = request.original_url
    busqueda.formato = request.format.symbol.to_s
    busqueda.resultados_avanzada

    @totales = busqueda.totales
    @por_categoria = busqueda.por_categoria || []
    @taxones = busqueda.taxones

    response.headers['x-total-entries'] = @totales.to_s if @totales > 0

    respond_to do |format|
      if params[:solo_categoria].present? && @taxones.length > 0 && pagina == 1  # Imprime el inicio de un TAB
        format.html { render :partial => 'busquedas/resultados' }
        format.json { render json: {taxa: @taxones} }
        format.xlsx { descargar_taxa_excel }
      elsif pagina > 1 && @taxones.length > 0  # Imprime un set de resultados con el scrolling
        format.html { render :partial => 'busquedas/_resultados' }
        format.json { render json: {taxa: @taxones} }
      elsif (@taxones.length == 0 || @totales == 0) && pagina > 1  # Cuando no hay resultados en la busqueda o el scrolling
        format.html { render plain: '' }
        format.json { render json: {taxa: []} }
      elsif params[:checklist].present? && params[:checklist].to_i == 1  # Imprime el checklist de la taxa dada
        format.html { render 'busquedas/checklists' }
        format.pdf do  #Para imprimir el listado en PDF
          ruta = Rails.root.join('public', 'pdfs').to_s
          fecha = Time.now.strftime("%Y%m%d%H%M%S")
          pdf = "#{ruta}/#{fecha}_#{rand(1000)}.pdf"
          FileUtils.mkpath(ruta, :mode => 0755) unless File.exists?(ruta)

          render :pdf => 'listado_de_especies',
                 :save_to_file => pdf,
                 #:save_only => true,
                 :template => 'busquedas/checklists.pdf.erb',
                 :encoding => 'UTF-8',
                 :wkhtmltopdf => CONFIG.wkhtmltopdf_path,
                 :orientation => 'Landscape'
        end
        format.xlsx do  # Falta implementar el excel de salida
          @columnas = @taxones.to_a.map(&:serializable_hash)[0].map{|k,v| k}
        end
      else  # Ojo si no entro a ningun condicional desplegará el render normal (resultados.html.erb)
        filtros_iniciales
        set_filtros

        format.html { render action: 'resultados' }
        format.json { render json: { taxa: @taxones, x_total_entries: @totales, por_categroria: @por_categoria.present? ? @por_categoria : [] } }
        format.xlsx { descargar_taxa_excel }
      end

    end  # end respond_to
  end

  # REVISADO: La descarga de taxa en busqueda basica o avanzada
  def descargar_taxa_excel
    lista = Lista.new
    columnas = Lista::COLUMNAS_DEFAULT + Lista::COLUMNAS_RIESGO_COMERCIO + Lista::COLUMNAS_CATEGORIAS_PRINCIPALES
    lista.columnas = columnas.join(',')
    lista.formato = 'xlsx'
    lista.cadena_especies = request.original_url
    lista.usuario_id = 0  # Quiere decir que es una descarga, la guardo en lista para tener un control y poder correr delayed_job
    @atributos = columnas

    if @totales <= 200  # Si son menos de 200, es optimo para bajarlo en vivo
      # el nombre de la lista es cuando la bajo ya que no metio un correo
      lista.nombre_lista = Time.now.strftime("%Y-%m-%d_%H-%M-%S-%L") + '_taxa_EncicloVida'
      @taxones = lista.datos_descarga(@taxones)

      if Rails.env.production?  # Solo en produccion la guardo
        render(xlsx: 'resultados') if lista.save
      else
        render xlsx: 'resultados'
      end

    elsif @totales > 200  # Creamos el excel y lo mandamos por correo por medio de delay_job, mas de 200
      # Para saber si el correo es correcto y poder enviar la descarga
      if Usuario::CORREO_REGEX.match(params[:correo]) ? true : false
        # el nombre de la lista es cuando la solicito? y el correo
        lista.nombre_lista = Time.now.strftime("%Y-%m-%d_%H-%M-%S-%L") + "_taxa_EncicloVida|#{params[:correo]}"

        if Rails.env.production?
          lista.delay(queue: 'descargar_taxa').to_excel({ busqueda: @taxones.to_sql, es_busqueda: true, correo: params[:correo], original_url: request.original_url.gsub('.xlsx?','?') }) if lista.save
        else  # Para develpment o test
          lista.to_excel({ busqueda: @taxones.to_sql, es_busqueda: true, correo: params[:correo], original_url: request.original_url.gsub('.xlsx?','?') }) if lista.save
        end

        render json: { estatus: 1 }
      else  # Por si no puso un correo valido
        render json: { estatus: 0 }
      end

    else  # No entro a ningun condicional, es un error
      render json: { estatus: 0 }
    end  # end totoales
  end  # end metodo

  # REVISADO: Parametros para poner en los filtros y saber cual escogio
  def set_filtros
    @setParams = {}

    params.each do |k,v|
      # Evitamos valores vacios
      next unless v.present?

      case k
        when 'id', 'nombre', 'por_pagina'
          @setParams[k] = v
        when 'edo_cons', 'dist', 'prior', 'estatus'
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
end
