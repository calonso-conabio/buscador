module BusquedasHelper

  # Opciones default para el bootstrap-select plugin
  @@opciones = { class: 'selectpicker form-control form-group', 'data-live-search-normalize': true, 'data-live-search': true, 'data-selected-text-format': 'count', 'data-select-all-text': 'Todos', 'data-deselect-all-text': 'Ninguno', 'data-actions-box': true, 'data-none-results-text': 'Sin resultados para {0}', 'data-count-selected-text': '{0} seleccionados', title: '- - Selecciona - -', multiple: true, 'data-sanitize': false }

  @@html = ''
  #@@bibliografias = []

  # REVISADO: Filtros para los grupos icónicos en la búsqueda avanzada vista general
  def radioGruposIconicos(resultados = false)
    def arma_span(taxon)
      "<label>#{radio_button_tag('id_gi', taxon.id, false, id: "id_gi_#{taxon.id}")}<span class='mx-1'><span title='#{taxon.nombre_comun_principal}' class='#{taxon.nombre_cientifico.parameterize}-ev-icon btn-title'></span></span></label>"
    end

    radios = ''
    radios << '<div class="col-md">'
    radios << '<h6><strong>Grupos de animales</strong></h6>'
    @animales.each do |taxon|  # Para tener los grupos ordenados
      radios << arma_span(taxon)
    end
    radios << '</div>'
    radios << '<div class="w-100"></div>' if resultados

    radios << '<div class="col-md">'
    radios << '<h6><strong>Grupos de plantas</strong></h6>'
    @plantas.each do |taxon|  # Para tener los grupos ordenados
      radios << arma_span(taxon)
    end
    radios << '</div>'
    radios << '<div class="w-100"></div>' if resultados

    "<div class='row'>#{radios}</div>"
  end

  # REVISADO: Filtros para categorías de riesgo y comercio internacional
  def checkboxEstadoConservacion(opciones={})
    opc = @@opciones.merge(opciones)
    options = @nom_cites_iucn_todos.map{ |k,v| [t(k), v.map{ |val| [val.descripcion.gsub('-eval',''), val.id, { class: "#{val.descripcion.estandariza}-ev-icon f-fuentes" }] }] }
    select_tag('edo_cons', grouped_options_for_select(options), opc)
  end

  # REVISADO: Filtros para Tipos de distribuciónes
  def checkboxTipoDistribucion(opciones={})
    opc = @@opciones.merge(opciones)
    options = @distribuciones.map{ |d| [d.descripcion, d.id, { class: "#{d.descripcion.estandariza}-ev-icon f-fuentes" }] }
    select_tag('dist', options_for_select(options), opc)
  end

  # REVISADO: Filtros para Especies prioritarias para la conservación
  def checkboxPrioritaria(opciones={})
    opc = @@opciones.merge(opciones)
    options = @prioritarias.map{ |p| [p.descripcion, p.id, { class: "#{p.descripcion.estandariza}-ev-icon f-fuentes" }] }
    select_tag('prior', options_for_select(options), opc)
  end

  # REVISADO: Filtros para estatus taxonómico en la busqueda avanzada
  def checkboxSoloValidos
    "<label for='estatus'><span title='Solo válidos/aceptados'>Solo válidos/aceptados</span></label> #{check_box_tag('estatus[]', 2, false, id: "estatus_2", class:'form-control')}"
  end

  def selectUsos(opciones={})
    opc = @@opciones.merge(opciones)
    options = @usos.map{ |u| [u.descripcion, u.id, { class: "f-fuentes" }] }
    select_tag('uso', options_for_select(options), opc)
  end

  def selectAmbiente(opciones={})
    opc = @@opciones.merge(opciones)
    options = @ambientes.map{ |a| [a.descripcion, a.id, { class: "#{a.descripcion.estandariza}-ev-icon f-fuentes" }] }
    select_tag('ambiente', options_for_select(options), opc)
  end

  def selectRegiones(opciones={})
    opc = @@opciones.merge(opciones)
    options = @regiones.map{ |k,v| [t("regiones.#{k.estandariza}"), v.map{ |val| [k.estandariza == 'estado' ? t("estados.#{val.nombre_region.estandariza}", default: val.nombre_region) : t("ecorregiones-marinas.#{val.nombre_region.estandariza}", default: val.nombre_region), val.id, { class: "#{val.nombre_region.estandariza}-ev-icon f-fuentes" }] }] }
    select_tag('reg', grouped_options_for_select(options), opc)
  end

  # Si la búsqueda ya fue realizada y se desea generar un checklist, unicamente se añade un parametro extra y se realiza la búsqueda as usual
  def checklist(datos)
    if datos[:totales] > 0
      sin_page_per_page = datos[:request].split('&').map{|attr| attr if !attr.include?('pagina=')}
      peticion = sin_page_per_page.compact.join('&')
      peticion << "&por_pagina=#{datos[:totales]}&checklist=1"
    else
      ''
    end
  end

  # Para las descargas
  def campoCorreo(recurso)
    html = ''

    if usuario_signed_in?
      html << text_field_tag('correo-' + recurso, current_usuario.email, class: 'form-control d-none', placeholder: 'correo ...')
    else
      html << label_tag('correo-'+recurso, 'Correo electrónico ', class: 'control-label')
      html << text_field_tag('correo-'+recurso, nil, class: 'form-control', placeholder: 'correo ...')
    end

    html
  end

  # El boton de las descargas
  def botonDescarga(recurso, checklist = false)
    if usuario_signed_in? || checklist
      "<button type='button' class='btn btn-success' id='boton-descarga-#{recurso}'>Enviar</button>"
    else
      "<button type='button' class='btn btn-success' id='boton-descarga-#{recurso}' disabled='disabled'>Enviar</button>"
    end
  end

  # Despliega el checklist
  def generaChecklist(taxon)

    @@html = ''
    nombre_cientifico = "<text class='f-nom-cientifico-checklist'>#{link_to(taxon.nombre_cientifico, especie_url(taxon), target: :_blank)}</text>"

    unless taxon.especie_o_inferior?
      cat = taxon.nombre_categoria_taxonomica
      @@html << "<text class='f-categoria-taxonomica-checklist'>#{cat}</text> #{nombre_cientifico}"
      @@html << " #{taxon.nombre_autoridad}"
    else
      @@html << nombre_cientifico
      @@html << " #{taxon.nombre_autoridad}"
      bibliografiaNombreChecklist(taxon)

      @@html << '<div>'
      huesped_hospedero = sinonimosBasonimoChecklist(taxon)
      cats_riesgo = catalogoEspecieChecklist(taxon)
      distribucionChecklist(taxon)
      nombresComunesChecklist(taxon)
      @@html << huesped_hospedero if huesped_hospedero.present?
      @@html << cats_riesgo if cats_riesgo.present?
      @@html << '</div>'
    end

    @@html
  end

  # Devuelve los nombres comunes agrupados por lengua, solo de catalogos
  def nombresComunesChecklist(taxon)
    return unless params[:f_check].present?
    return unless params[:f_check].include?('nom_com')

    nombres = taxon.dame_nombres_comunes_catalogos
    return '' unless nombres.any?
    html = "<label class='etiqueta-checklist'>Nombre(s) común(es):</label> "

    nombres_completos = []
    nombres.each do |hash_nombres|
      lengua = hash_nombres.keys.first
      nombres_completos << "<span>#{hash_nombres[lengua].uniq.sort.join(', ')} <sub>(#{lengua})</sub></span>"
    end

    html << nombres_completos.join('; ') + '.' if nombres_completos.any?
    @@html << "<p class='m-0'>#{html}</p>"
  end

  # Devuelve una lista de sinónimos y basónimos
  def sinonimosBasonimoChecklist(taxon)
    sinonimos_basonimo = {sinonimos: [], basonimo: [], hospedero: [], parasito: []}

    estatus_permitidos = []
    if params[:f_check].present? && !params[:f_check].include?('val')
      estatus_permitidos << 1
      estatus_permitidos << 2
    end

    if params[:f_check].present? && params[:f_check].include?('interac')
      estatus_permitidos << 7
    end

    # Retorna en caso de solo ser validos
    return unless estatus_permitidos.any?

    taxon.especies_estatus.each do |estatus|
      next unless estatus_permitidos.include?(estatus.estatus_id)
      next unless taxon_estatus = estatus.especie

      nombre_cientifico = "<text class='f-sinonimo-basonimo-checklist'>#{taxon_estatus.nombre_cientifico}</text> #{taxon_estatus.nombre_autoridad}"

      case estatus.estatus_id
      when 1
        sinonimos_basonimo[:sinonimos] << nombre_cientifico
      when 2
        sinonimos_basonimo[:basonimo] << nombre_cientifico
      when 7
        nombre_cientifico = "<text class='f-nom-cientifico-checklist'>#{taxon_estatus.nombre_cientifico}</text>"
        regiones = distribucionChecklist(taxon_estatus, false)

        if regiones.present? && regiones.any?
          if taxon.ancestry_ascendente_directo.include?(',213407,')  # Chordata equivale a parásito
            sinonimos_basonimo[:parasito] << "#{nombre_cientifico} <sub>(#{regiones.join(', ')})</sub>"
          elsif taxon.ancestry_ascendente_directo.include?(',132386,') || taxon.ancestry_ascendente_directo.include?(',132387,')  # Acantocephala o Platyhelminthes equivale a hospedero
            sinonimos_basonimo[:hospedero] << "#{nombre_cientifico} <sub>(#{regiones.join(', ')})</sub>"
          end
        else
          if taxon.ancestry_ascendente_directo.include?(',213407,')  # Chrodata equivale a parásito
            sinonimos_basonimo[:parasito] << nombre_cientifico
          elsif taxon.ancestry_ascendente_directo.include?(',132386,') || taxon.ancestry_ascendente_directo.include?(',132387,')  # Acantocephala o Platyhelminthes equivale a hospedero
            sinonimos_basonimo[:hospedero] << nombre_cientifico
          end
        end  # End if regiones.any?
      end  # End when 7
    end

    if sinonimos_basonimo[:basonimo].any?
      @@html << "<p class='m-0'><label class='etiqueta-checklist'>Basónimo:</label> #{sinonimos_basonimo[:basonimo].join('; ')}</p>"
    end

    if sinonimos_basonimo[:sinonimos].any?
      @@html << "<p class='m-0'><label class='etiqueta-checklist'>Sinónimo(s):</label> #{sinonimos_basonimo[:sinonimos].join('; ')}</p>"
    end

    huesped_hospedero = if sinonimos_basonimo[:parasito].any?
                          "<p class='mt-4'><label class='etiqueta-checklist'>Interacciones biológicas</label></p><p><label class='etiqueta-checklist'>Parásito(s):</label> #{sinonimos_basonimo[:parasito].join('; ')}</p>"
                        elsif sinonimos_basonimo[:hospedero].any?
                          "<p class='mt-4'><label class='etiqueta-checklist'>Interacciones biológicas</label></p><p><label class='etiqueta-checklist'>Hopedero(s):</label> #{sinonimos_basonimo[:hospedero].join('; ')}</p>"
                        end

    huesped_hospedero if huesped_hospedero.present?
  end

  # Regresa el tipo de distribucion
  def tipoDistribucionChecklist(taxon)
    if params[:f_check].present? && params[:f_check].include?('tipo_dist')
      taxon.tipos_distribuciones.map(&:descripcion).uniq
    end
  end

  # Regresa todas las relaciones del catalogo de especies, incluye especies en riesgo
  def catalogoEspecieChecklist(taxon)
    catalogos_permitidos = []
    res = { catalogos: [], riesgo: { 'NOM-059-SEMARNAT 2010' => [], 'IUCN' => [], 'CITES' => [] } }

    tipo_dist = tipoDistribucionChecklist(taxon)
    res[:catalogos] = tipo_dist if tipo_dist

    catalogos_permitidos << 4 if params[:f_check].present? && params[:f_check].include?('cat_riesgo')
    catalogos_permitidos << 2 if params[:f_check].present? && params[:f_check].include?('amb')
    catalogos_permitidos << 16 if params[:f_check].present? && params[:f_check].include?('residencia')
    catalogos_permitidos << 18 if params[:f_check].present? && params[:f_check].include?('formas')

    if catalogos_permitidos.any?
      taxon.catalogos.each do |catalogo|
        next unless catalogos_permitidos.include?(catalogo.nivel1)

        case catalogo.nivel1
        when 4
          next unless [1,2,3].include?(catalogo.nivel2)  # Solo las categorias de riesgo y comercio

          case catalogo.nivel2
          when 1
            res[:riesgo]['NOM-059-SEMARNAT 2010'] << catalogo.descripcion
          when 2
            res[:riesgo]['IUCN'] << catalogo.descripcion
          when 3
            res[:riesgo]['CITES'] << catalogo.descripcion
          end
        else
          res[:catalogos] << catalogo.descripcion
        end
      end
    end

    if res[:catalogos].any?
      @@html << "<p class='etiqueta-checklist m-0'>#{res[:catalogos].join(', ')}</p>"
    end

    cats = []
    res[:riesgo].each do |k,v|
      next unless v.present?
      cats << "#{k}: #{v.join(',')}"
    end

    cats.any? ? "<p class='f-categorias-riesgo-checklist text-right m-0'>#{cats.join('; ')}</p>" : nil
  end

  def distribucionChecklist(taxon, seccion=true)
    return unless params[:f_check].present?
    return unless params[:f_check].include?('dist') || params[:f_check].include?('interac')

    regiones = taxon.regiones.map{ |r| t("estados_siglas.#{r.nombre_region.estandariza}") if r.tipo_region_id == 2 }.flatten.compact.sort
    return regiones unless seccion
    @@html << "<p class='m-0'><label class='etiqueta-checklist'>Distribución en México:</label> #{regiones.join(', ')}</p>" if regiones.any?
  end

  # Va imprimiendo los numeros de las bibliografias de los nombres cientificos
  def bibliografiaNombreChecklist(taxon)
    return unless params[:f_check].present?
    return unless params[:f_check].include?('biblio')
    referencias = []

    taxon.bibliografias.each do |bibliografia|
      if indice = @bibliografias.index(bibliografia.cita_completa)
        referencias << (indice+1)
      else
        @bibliografias << bibliografia.cita_completa
        referencias << @bibliografias.length
      end
    end

    @@html << " <sup><strong>[#{referencias.sort.map{ |r| link_to(r,"#biblio-checklist-#{r}", target: :_self) }.join(',')}]</strong></sup>" if referencias.any?
  end

  # Imprime las bibliografias al final
  def bibliografiasChecklist
    return unless params[:f_check].present?
    return unless params[:f_check].include?('biblio')
    return unless @bibliografias.any?

    html = "<h5 class='etiqueta-checklist'>Bibliografía</h5>"

    @bibliografias.each_with_index do |bibliografia, indice|
      html << "<p id='biblio-checklist-#{indice+1}'>#{bibliografia} <sup><strong>[#{indice+1}]</strong></sup></p>"
    end

    html.html_safe
  end

  # Los checkbox para que el usuario decida que descargar
  def campoDescargaChecklist
    campos = { tipo_dist: 'Tipo de distribución', cat_riesgo: 'Categorías de riesgo y comercio internacional', dist: 'Distribución (reportada en literatura)', amb: 'Ambiente', val: 'Solo válidos/aceptados', nom_com: 'Nombres comunes', biblio: 'Bibliografía', residencia: 'Categoría de residencia (aves)', formas: 'Formas de crecimiento (plantas)', interac: 'Interacciones biológicas' }
    checkBoxes = '<h6>Selecciona los campos a desplegar en el checklist</h6>'

    campos.each do |valor, label|
      checkBoxes << "<div class='custom-control custom-switch'>"
      checkBoxes << check_box_tag('f_check[]', valor, false, class: 'custom-control-input', id: "f_check_#{valor}")
      checkBoxes << "<label class = 'custom-control-label' for='f_check_#{valor}'>#{label}</label>"
      checkBoxes << "</div>"
    end

    checkBoxes.html_safe
  end

end
