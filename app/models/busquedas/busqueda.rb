class Busqueda
  attr_accessor :params, :taxones, :totales, :por_categoria, :es_cientifico, :original_url, :formato,
                :pagina, :por_pagina, :offset, :taxon, :estadisticas

  POR_PAGINA = [50, 100, 200]
  POR_PAGINA_PREDETERMINADO = POR_PAGINA.first

  NIVEL_CATEGORIAS = [
      ['inferior o igual a', '>='],
      ['inferior a', '>'],
      ['igual a', '='],
      ['superior o igual a', '<='],
      ['superior a', '<']
  ]

  GRUPOS_REINOS = %w(Animalia Plantae Fungi Prokaryotae Protoctista)
  GRUPOS_ANIMALES = %w(Mammalia Aves Reptilia Amphibia Actinopterygii Petromyzontidae Myxini Chondrichthyes
Arachnida Insecta Mollusca Crustacea Annelida Myriapoda Echinodermata Cnidaria Porifera)
  GRUPOS_PLANTAS = %w(Bryophyta Anthocerotophyta Polypodiidae Pinidae Cycadidae Lilianae Magnoliidae)

  # REVISADO: Inicializa los objetos busqueda
  def initialize
    self.taxones = Especie.left_joins(:categoria_taxonomica, :adicional, :scat).distinct
    self.totales = 0
  end

  # REVISADO: Filtros de tipos de distribucion
  def tipo_distribucion
    if params[:dist].present? && params[:dist].any?
      self.taxones = taxones.where("#{TipoDistribucion.table_name}.#{TipoDistribucion.attribute_alias(:id)} IN (?)", params[:dist]).left_joins(:tipos_distribuciones)
    end
  end

  def busca_estadisticas

    if params[:controller]=='estadisticas'

      # Si se definió condición para conteo de valores:
      conteo = '> 0'
      if params["tipoResultado"].present?
        case params["tipoResultado"]
          when 'mayorCero'
            conteo = '> 0'
          when 'cero'
            conteo = '= 0'
          when 'mayorIgualCero'
            conteo = '>= 0'
          else
            conteo = '> 0'
        end
      end

      # Construir la clausula WHERE a partir de los parámetros
      estadisticas_a_mostrar = []
      # Si se definieron las estadísticas
      if params["showEstadisticas"].present?
        estadisticas_a_mostrar = params["showEstadisticas"]
      else
        # Si no, mostrar todas
        Estadistica.all.each do |estadistica|
          next if Estadistica::ESTADISTICAS_QUE_NO.index(estadistica.id)
          estadisticas_a_mostrar << estadistica.id
        end
      end

      el_where = "("
      flag = false
      estadisticas_a_mostrar.each do |estadistica|
        unless flag
          el_where << "enciclovida.especies_estadistica.estadistica_id = #{estadistica}"
          flag = true
        else
          el_where << " OR enciclovida.especies_estadistica.estadistica_id = #{estadistica}"
        end
      end
      el_where << ")"
      # Agregarle el filtro de conteo
      el_where << " AND enciclovida.especies_estadistica.conteo #{conteo} "

      # EJECUTAR QUERY con el WHERE CONSTRUIDO
      resultados = taxones.joins(:especie_estadisticas).distinct.where(el_where).group(:estadistica_id).size

      # Iteramos los resultados y guardamos
      self.estadisticas = {}
      resultados.each do |clave, valor|
        nombre_estd = Estadistica.where("id = #{clave}").first.descripcion_estadistica
        conteo_estd = valor
        self.estadisticas[clave] = {
            'nombre_estadistica': nombre_estd,
            'conteo': conteo_estd
        }
      end
    end

  end

  # REVISADO: filtros de categorias de riesgo, nivel de prioridad
  def estado_conservacion
    if params[:edo_cons].present? || params[:prior].present?
      catalogos = (params[:edo_cons] || []) + (params[:prior] || [])
      self.taxones = taxones.where("#{Catalogo.table_name}.#{Catalogo.attribute_alias(:id)} IN (?)", catalogos).left_joins(:catalogos)
    end
  end

  # REVISADO: Por si selecciono un grupo iconico, eligio del autocomplete un taxon o escribio un nombre
  def por_id_o_nombre
    if params[:id].present?  # Tiene mas importancia si escogio por id
      begin
        self.taxon = Especie.find(params[:id])
        true
      rescue
        self.taxones = Especie.none
        false
      end
    elsif params[:nombre].present?
      self.taxones = taxones.caso_nombre_comun_y_cientifico(params[:nombre].strip).left_joins(:nombres_comunes)
      true
    else  # Si no esta presente que siga con el flujo del programa
      true
    end
  end

  # REVISADO: Los resultados por categoria taxonomica de acuerdo a las pestañas
  def conteo_por_categoria_taxonomica
    return if !(pagina == 1 && params[:solo_categoria].blank? && formato != 'xlsx')

    por_categoria = taxones.
        select(:categoria_taxonomica_id, "#{CategoriaTaxonomica.attribute_alias(:nombre_categoria_taxonomica)} AS nombre_categoria_taxonomica, COUNT(DISTINCT #{Especie.table_name}.#{Especie.attribute_alias(:id)}) AS cuantos").
        group(:categoria_taxonomica_id, CategoriaTaxonomica.attribute_alias(:nombre_categoria_taxonomica)).
        order(CategoriaTaxonomica.attribute_alias(:nombre_categoria_taxonomica))

    self.por_categoria = por_categoria.map{|cat| {nombre_categoria_taxonomica: cat.nombre_categoria_taxonomica,
                                                  cuantos: cat.cuantos, url: "#{original_url}&solo_categoria=#{cat.categoria_taxonomica_id}",
                                                  categoria_taxonomica_id: cat.categoria_taxonomica_id}}
  end

  # REVISADO: Solo la categoria que escogi, en caso de haber escogido una pestaña en especifico
  def solo_categoria
    if params[:solo_categoria].present?
      self.taxones = taxones.where(CategoriaTaxonomica.attribute_alias(:id) => params[:solo_categoria])
    end
  end

  # REVISADO: Pone el estatus de acuerdo a la vista
  def estatus
    if es_cientifico
      self.taxones = taxones.where(estatus: params[:estatus]) if params[:estatus].present? && params[:estatus].length > 0
    else  # En la vista general solo el valido
      self.taxones = taxones.where(estatus: 2)
    end
  end

  # REVISADO: Condicion para regresar solo los taxones publicos
  def solo_publicos
    self.taxones = taxones.where("#{Scat.table_name}.#{Scat.attribute_alias(:publico)} = 1").left_joins(:scat)
  end

  # REVISADO: ALgunos valores como el offset, pagina y por pagina
  def paginado_y_offset
    self.pagina = (params[:pagina] || 1).to_i
    self.por_pagina = params[:por_pagina].present? ? params[:por_pagina].to_i : POR_PAGINA_PREDETERMINADO
    self.offset = (pagina-1)*por_pagina
  end

  # REVISADO: Por si carga la pagina de un inicio, o es una descarga
  def dame_totales
    if (pagina == 1 && params[:solo_categoria].blank?) || formato == 'xlsx'
      self.totales = taxones.count
    end
  end


  protected

  # REVISADO: Regresa el ID de la centralizacion de acuerdo a uin nombre comun dado
  def id_referencia_a_nombre_comun(id_referencia)
    id_referencia.to_s[1..6].to_i
  end
end
