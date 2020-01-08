module EspeciesHelper

  def tituloNombreCientifico(taxon, params={})

    nombre = if taxon.x_nombre_comun_principal.present?
               taxon.x_nombre_comun_principal
             else
               begin  # Es con un try porque no toda consulta le hace un join a adicionales
                 taxon.nombre_comun_principal
               rescue  # hacemos el join a adicionales
                 if a = taxon.adicional
                   a.nombre_comun_principal
                 else
                   ''
                 end
               end
             end.try(:capitalize)

    if I18n.locale.to_s == 'es-cientifico'
      if taxon.especie_o_inferior?   # Las especies llevan otro tipo de formato en nombre
        if params[:title]
          "#{taxon.nombre_cientifico} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}"
        elsif params[:link]
          if taxon.x_nombre_comun_principal.present?
            "#{ponItalicas(taxon,true)} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]} ----------> #{taxon.x_nombre_comun_principal.capitalize}".html_safe
          else
            "#{ponItalicas(taxon,true)} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}".html_safe
          end
        elsif params[:show]
          "#{ponItalicas(taxon)} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}".html_safe
        else
          'Ocurrio un error en el nombre'.html_safe
        end
      else
        if params[:title]
          "#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}".html_safe
        elsif params[:link]
          "#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{link_to("#{taxon.nombre_cientifico}", especie_path(taxon))} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}".html_safe
        elsif params[:show]
          "#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico} #{taxon.nombre_autoridad} #{Especie::ESTATUS_VALOR[taxon.estatus]}".html_safe
        else
          'Ocurrio un error en el nombre'.html_safe
        end
      end

    else   #vista general

      if taxon.especie_o_inferior?  # Las especies llevan otro tipo de formato en nombre
        if params[:title]
          nombre.present? ? "#{nombre} (#{taxon.nombre_cientifico})".html_safe : taxon.nombre_cientifico
        elsif params[:link]
          nombre.present? ? "<h5>#{nombre}</h5><h5>#{link_to(ponItalicas(taxon).html_safe, especie_path(taxon))}</h5>" : "<h5>#{ponItalicas(taxon,true)}</h5>"
        elsif params[:show]
          nombre.present? ? "#{nombre} (#{ponItalicas(taxon)})".html_safe : ponItalicas(taxon).html_safe
        else
          'Ocurrio un error en el nombre'.html_safe
        end
      else
        if params[:title]
          nombre.present? ? "#{nombre} (#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico})".html_safe :
              "#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico}".html_safe
        elsif params[:link]
          nombre.present? ? "<h5>#{nombre}</h5><h5>#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{link_to("#{taxon.nombre_cientifico}", especie_path(taxon))}</h5>".html_safe : "<h5>#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{link_to(taxon.nombre_cientifico, especie_path(taxon))}</h5>".html_safe
        elsif params[:show]
          nombre.present? ? "#{nombre} (#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico})".html_safe :
              "#{taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica} #{taxon.nombre_cientifico}".html_safe
        else
          'Ocurrio un error en el nombre'.html_safe
        end
      end
    end
  end

  # Para separar SÓLO las italicas EN el nombre cientifico y la categoria taxonomica
  def ponItalicas(taxon, con_link = false)
    italicas = taxon.nombre_cientifico.gsub('subsp.','</i>subsp.<i>').gsub('var.','</i>var.<i>').gsub('f.','</i>f.<i>').
        gsub('subvar.','</i>subvar.<i>').gsub('subf.','</i>subf.<i>')

    if con_link
      "<a href=\"/especies/#{taxon.id}\"><i>#{italicas}</i></a>"
    else
      "<i>#{italicas}</i>"
    end
  end

  def enlacesDeTaxonomia(taxa, nuevo=false)        #ancestros del titulo
    enlaces = "<table width=\"1000\" id=\"enlaces_taxonomicos\"><tr><td>"

    taxa.ancestor_ids.push(taxa.id).each do |ancestro|
      if taxa.id == ancestro
        if nuevo
          e=Especie.find(ancestro)
          enlaces+= "#{link_to(image_tag(e.foto_principal, :alt => e.nombre_cientifico, :title => e.nombre_cientifico, :width => '40px'), e)} #{link_to(e.nombre, e)} (#{e.categoria_taxonomica.nombre_categoria_taxonomica}) > ?   "
        else
          enlaces+= "#{link_to(image_tag(taxa.foto_principal, :alt => taxa.nombre_cientifico, :title => taxa.nombre_cientifico, :width => '40px'), e)} #{taxa.nombre} (#{taxa.categoria_taxonomica.nombre_categoria_taxonomica}) > "
        end
      else
        e = Especie.find(ancestro)
        enlaces+= "#{link_to(image_tag(e.foto_principal, :alt => e.nombre_cientifico, :title => e.nombre_cientifico, :width => '40px'), e)} #{link_to(e.nombre, e)} (#{e.categoria_taxonomica.nombre_categoria_taxonomica}) > "
      end
    end
    "#{enlaces[0..-3]}</td></tr></table>".html_safe
  end

  # REVISADO: Regresa el arbol identado inicial en la ficha de especie
  def dameArbolIdentadoInicial(taxones)
    html = ''

    def creaLista(taxon, lista=nil)
      link = "#{link_to("<span class='glyphicon glyphicon-plus' aria-hidden='true' id='span_#{taxon.id}'></span>".html_safe, '',
                        :taxon_id => taxon.id, :class => 'sub_link_taxon btn btn-sm btn-link')}"
      nombre = tituloNombreCientifico(taxon, :link => true)
      "<ul id='ul_#{taxon.id}' class='nodo_mayor'><li class='links_arbol'>#{link} #{nombre}#{lista.present? ? lista : ''}</li></ul>"
    end

    taxones.each do |taxon|
      if html.present?
        html = creaLista(taxon, html)
      else
        html = creaLista(taxon)
      end
    end

    html.html_safe
  end

  # REVISADO: Regresa los taxones hijos del taxon en cuestion
  def dameArbolIdentadoHojas(taxones)
    html = ''

    taxones.each do |taxon|
      link = "#{link_to("<span class='glyphicon glyphicon-plus' aria-hidden='true' id='span_#{taxon.id}'></span>".html_safe, '',
                        :taxon_id => taxon.id, :class => 'sub_link_taxon btn btn-sm btn-link')}"
      nombre = tituloNombreCientifico(taxon, :link => true)
      html << "<ul id='ul_#{taxon.id}' class='nodo_mayor'><li class='links_arbol'>#{link} #{nombre}</li></ul>"
    end

    html.html_safe
  end

  # REVISADO: Nombres comunes con su bibliografia como referencia
  def dameNomComunesBiblio(taxon)
    html = ''

    def creaLista(nombre, opc={})
      # TODO: Poner las bibliografias en un modal, el actual esta roto
      bibliografias = nombre.bibliografias.con_especie(opc[:taxon]).map(&:cita_completa)
      html = "<li>#{nombre.nombre_comun} <sub><i>#{nombre.lengua}</i></sub></li>"

      if bibliografias.any?
        biblio_html = "<ul>#{bibliografias.map{ |b| "<li>#{b}</li>" }.join('')}</ul>"
        html << " <a tabindex='0' class='btn btn-link biblio-cat' role='button' data-toggle='popover' data-trigger='focus'
title='Bibliografía' data-content=\"#{biblio_html}\">Bibliografía</a>"
      end

      html
    end

    taxon.nombres_comunes.distinct.order(:nombre_comun).each do |nom|
      html << creaLista(nom, taxon: taxon)
    end

    "<p><strong>Nombres comunes</strong></p><ul>#{html}</ul>".html_safe
  end

  # REVISADO: Otros atributos simples del modelo especie
  def dameOtrosAtributos(taxon)
    otros_attr = {'Cita nomenclatural' => 'cita_nomenclatural', 'Fuente de la información' => 'sist_clas_cat_dicc',
                  'Anotación' => 'anotacion', 'Fecha de ultima modificación' => 'updated_at'}
    html = ''

    def creaContenedor(taxon, opc={})
      puts opc[:attr].inspect
      valor = taxon.send(opc[:attr])

      if valor.present?
        valor = valor.strftime('%Y-%m-%d') if opc[:attr] == 'updated_at'
        "<p><strong>#{opc[:nom]}</strong><ul><li>#{valor}</li></ul></p>"
      else
        ''
      end
    end

    otros_attr.each do |nom, attr|
      html << creaContenedor(taxon, {nom: nom, attr: attr})
    end

    html.html_safe
  end

  # REVISADO: La distribucion reportada en literatura, para el show de especies en la pestaña de catalogos
  def dameDistribucionLiteratura(taxon)
    def creaLista(regiones)
      lista = []

      regiones.each do |id, datos|
        lista << "<li>#{datos[:nombre]}</li>"
        lista << " <a tabindex='0' class='btn btn-link biblio-cat' role='button' data-toggle='popover' data-trigger='focus'
title='Bibliografía' data-content='#{datos[:observaciones]}'>Bibliografía</a>" if datos[:observaciones].present?

        if datos[:reg_desc].any?
          sub_reg = creaLista(datos[:reg_desc])
          lista << sub_reg
        end
      end

      "</strong><ul>#{lista.join('')}</ul>"
    end

    regiones = taxon.regiones.select_observaciones.validas.distinct
    reg_asignadas = Region.regiones_asignadas(regiones)
    "<p><strong>Distribución reportada en literatura</strong>#{creaLista(reg_asignadas)}</p>".html_safe
  end

  # REVISADO: Una misma funcion para sinonimos u homonimos
  def dameSinonimosUhomonimos(taxon, opciones={})
    def creaContenedor(recurso, opciones={})
      "<strong>#{opciones[:tipo_recurso]}: </strong><small>#{recurso.join(', ')}</small>"
    end

    def creaLista(taxones, opciones={})
      html = ''

      taxones.each do |taxon|
        html << "<li>#{tituloNombreCientifico(taxon, show: true)}</li>"

        bibliografias = taxon.bibliografias.map(&:cita_completa)

        if bibliografias.any?
          biblio_html = "<ul>#{bibliografias.map{ |b| "<li>#{b}</li>" }.join('')}</ul>"
          html << " <a tabindex='0' class='btn btn-link biblio-cat' role='button' data-toggle='popover' data-trigger='focus'
title='Bibliografía' data-content=\"#{biblio_html}\">Bibliografía</a>"
        end
      end

      "<p><strong>#{opciones[:tipo_recurso]} </strong></p><ul>#{html}</ul>"
    end

    ids = taxon.especies_estatus.send(opciones[:tipo_recurso].estandariza).map(&:especie_id2)
    return '' unless ids.any?
    taxones = Especie.find(ids)

    if opciones[:tab_catalogos]
      creaLista(taxones, opciones).html_safe
    else
      recurso = taxones.map{ |t| tituloNombreCientifico(t, show: true) }
      creaContenedor(recurso, opciones).html_safe
    end
  end

  # REVISADO: Pone el estatus taxonómico de la especie, si no existe en la variable ESTATUS_SIGNIFICADO ponerla
  def dameEstatus(taxon)
    "<p><strong>Estatus taxonómico</strong><ul><li>#{Especie::ESTATUS_SIGNIFICADO[taxon.estatus]}</li></ul></p>".html_safe
  end

  # REVISADO: Pone las respectivas categorias de riesgo, distribucion y ambiente en el show de especies; pestaña de catalogos
  def dameCaracteristica(taxon)
    html = ''
    caracteristicas = taxon.nom_cites_iucn_ambiente_prioritaria_bibliografia

    def creaCaracteristica(valores)
      html = ''
      biblio = "<ul>#{valores[:bibliografias].map{ |b| "<li>#{b}</li>" }.join('')}</ul>"
      biblio_html = " <a tabindex='0' class='btn btn-link biblio-cat' role='button' data-toggle='popover' data-trigger='focus'
title='Bibliografía' data-content='#{biblio}'>Bibliografía</a>"
      obs_html = valores[:observaciones].any? ? "<p>Observaciones: #{valores[:observaciones].join('<hr />')}</p>" : ''

      valores[:descripciones].each do |l|
        html << "<li>#{l}</li> #{biblio_html} #{obs_html}"
      end

      "<p><strong>#{valores[:nombre_catalogo]}</strong><ul>#{html}</ul></p>"
    end

    caracteristicas.each do |key, valores|
      html << creaCaracteristica(valores)
    end

    html.html_safe
  end

  # REVISADO: Regresa la distribucion de catalogos
  def dameDistribucion(taxon)
    html =''

    def creaLista(distribucion)
      "<li>#{distribucion}</li>"
    end

    distribuciones = taxon.tipo_distribucion(tab_catalogos: true).values.flatten.compact

    distribuciones.each do |distribucion|
      html << creaLista(distribucion)
    end

    html.present? ? "<p><strong>Tipo de distribución</strong><ul>#{html}</ul></p>".html_safe : html
  end

  # REVISADO: Pone las respectivas categorias de riesgo, distribucion y ambiente en el show de especies
  def ponCaracteristicaDistribucionAmbienteTaxon(taxon)
    response = []
    caracteristicas = [taxon.tipo_distribucion.values, taxon.nom_cites_iucn_ambiente_prioritaria({iucn_ws: true}).map{|h| h.values}].flatten

    caracteristicas.each{ |x|
      response << "<span class='btn-title' title='#{x}'><i class ='#{x.estandariza}-ev-icon'></i></span>"
    }

    response << "<small class='glyphicon glyphicon-question-sign text-primary ' onclick=\"$('#panelCaracteristicaDistribucionAmbiente').toggle(600,
'easeOutBounce')\" style='cursor: pointer; margin-left: 10px;'></small>" if response.any?
    response.join.html_safe
  end

  # REVISADO: Pone la simbologia en la ficha de la especie
  def ponCaracteristicaDistribucionAmbienteTodos
    response = {}

    def creaSpan(recurso)
      nombre = recurso.descripcion
      icono  = "<i class = '#{recurso.descripcion.parameterize}-ev-icon'></i>"
      "<span title='#{nombre}' class='btn-title' alt='#{nombre}'>#{icono}</span>"
    end

    Catalogo.nom_cites_iucn_todos.each do |k, valores|
      valores.each do |edo|
        response[k] ||=[]
        response[k] << creaSpan(edo)
      end
    end

    TipoDistribucion.distribuciones.each do |tipoDist|
      response[:tipoDistribucion] ||= []
      response[:tipoDistribucion] << creaSpan(tipoDist)
    end

    Catalogo.ambiente_todos.each do |amb|
      response[:ambiente] ||=[]
      response[:ambiente] << creaSpan(amb)
    end

    Catalogo.prioritaria_todas.each do |prior|
      response[:prioritaria] ||=[]
      response[:prioritaria] << creaSpan(prior)
    end

    response
  end

  def ponBotonEditaIDNaturalista
    button_tag("Cambia URL Naturalista <span class='glyphicon glyphicon-pencil' aria-hidden='true'></span>".html_safe,
               id: 'cambiar_id_naturalista' ,  "data-toggle" => "modal", "data-target" => "#modal_cambia_id_naturalista" , :class => "btn btn-link btn-title", :title=>'Cambiar URL de Naturalista')
  end

  # REVISADO: Regresa las bibliografias de la especie del nombre cientifico en el show de especies
  def dameEspecieBibliografias(taxon)
    html = []

    taxon.bibliografias.each do |bib|
      html << "<li>#{bib.cita_completa}</li>" if bib.cita_completa.present?
    end

    html.any? ? "<p><strong>Bibliografía del nombre científico</strong><ul>#{html.join('')}</ul></p>".html_safe : ''
  end

  def esSinonimo (taxon)
    e = (taxon.instance_of? NombreComun) ? Especie.find(taxon.id).estatus : taxon.estatus #Debido a que se reemplaza
    # el id de NombreComun
    n = e == 1 ? "<s>#{taxon.nombre_cientifico}</s>" : taxon.nombre_cientifico
    n.html_safe
  end


  def imprime_media_bdi(item, type)
    copyright = "BDI - CONABIO"
    case type
      when 'photo'
        link_to("<img src='#{item.medium_url}' />".html_safe, '',
                "data-toggle" => "modal", "data-target" => "#modal_reproduce", :class => "btn btn-link btn-title modal-buttons",
                "data-type" => 'photo',
                "data-copyright" => copyright,
                "data-url" => item.medium_url,
                "data-author" => item.native_realname,
                "data-locality" =>  "No disponible",
                "data-observation"=> item.native_page_url
                )
      when 'video' # Datos fasos por ahora
        link_to("<img src='#{item.preview_img}' />".html_safe, '',
                "data-toggle" => "modal", "data-target" => "#modal_reproduce", :class => "btn btn-link btn-title modal-buttons",
                "data-type" => 'video',
                "data-copyright" => item.licencia.present? ? "<a href='#{item.licencia}' target='_blank'>#{copyright}</a>" : copyright,
                "data-observation"=> item.href_info,
                "data-url" => item.url_acces,
                "data-author" => item.autor,
                "data-locality" =>  item.localidad.present? ? item.localidad : "No disponible",
                "data-state" =>  item.municipio.present? ? item.municipio : nil)
    end
  end

  def imprimeMediaCornell(item,type)
    copyright = "Macaulay Library at The Cornell Lab of Ornithology"
    case type
    when 'photo'
      link_to("<img src='#{item['mlBaseDownloadUrl']}/#{item['assetId']}/320' />".html_safe, '',
              "data-toggle" => "modal", "data-target" => "#modal_reproduce", :class => "btn btn-link btn-title modal-buttons",
              "data-observation"=> item['citationUrl'], "data-url" => "#{item['mlBaseDownloadUrl']}/#{item['assetId']}/900",
              "data-type" => 'photo', "data-author" => item['userDisplayName'], "data-date" => item['obsDtDisplay']||='',
              "data-country" => item['countryName']||='', "data-state" => item['subnational1Name']||='', "data-locality" => item['locName']||='', "data-copyright" => copyright)
    when 'video'
      link_to("<img src='#{item['mlBaseDownloadUrl']}#{item['assetId']}/thumb' />".html_safe, '',
              "data-toggle" => "modal", "data-target" => "#modal_reproduce", :class => "btn btn-link btn-title modal-buttons",
              "data-observation"=> item['citationUrl'], "data-url" => "#{item['mlBaseDownloadUrl']}/#{item['assetId']}/video", "data-type" => 'video',
              "data-author" => item['userDisplayName'], "data-date" => item['obsDtDisplay']||='', "data-country" => item['countryName']||='',
              "data-state" => item['subnational1Name']||='', "data-locality" => item['locality']||='', "data-copyright" => copyright)
    when 'audio'
      link_to("<img src='#{item['mlBaseDownloadUrl']}#{item['assetId']}/poster' />".html_safe, '', "data-toggle" => "modal",
              "data-target" => "#modal_reproduce", :class => "btn btn-link btn-title modal-buttons", "data-observation"=> item['citationUrl'],
              "data-url" => "#{item['mlBaseDownloadUrl']}/#{item['assetId']}/audio", "data-type" => 'audio',
              "data-author" => item['userDisplayName'], "data-date" => item['obsDtDisplay']||='', "data-country" => item['countryName']||='',
              "data-state" => item['subnational1Name']||='', "data-locality" => item['locality']||='', "data-copyright" => copyright)
    end
  end

  def imprime_img_tropicos(item)
    copyright = "Missouri Botanical Garden"
    link_to("<img src='#{item['DetailJpgUrl']}'/>".html_safe, '', "data-toggle" => "modal",
            "data-target" => "#modal_reproduce",
            :class => "btn btn-link btn-title modal-buttons",
            "data-observation"=> item['DetailUrl'],
            "data-url" => item['DetailJpgUrl'],
            "data-type" => 'photo',
            "data-author" => item['Photographer'] ||= copyright,
            "data-copyright" => item['Copyright'] ||= copyright,
            "data-title" => item['NameText'] ||= '',
            "data-locality" => item['PhotoLocation'] ||= 'No disponible',
            "data-state" => '', "data-country" => '',
            "data-date" => item['PhotoDate'] ||= '',
            "data-tipodeimagen" => item['ImageKindText'],
            "data-caption" => item['Caption'],
            "data-descripcion" => item['ShortDescription']
            )

    # Información útil de servicio trópicos
    # Name: NameText || Caption
    # Specimen: SpecimenText
    # Short Description: ShortDescription
    # Image Kind: ImageKindText
    # Copyright: Copyright
    # Photographer: Photographer
    # Location: PhotoLocation
    # Date: PhotoDate
    #
    #  - - - Más comunes
    # 'NameText'
    # 'SpecimenText'
    # 'Caption'
    # 'ImageKindText'
    # 'Copyright'
    # 'LicenseUrl'
    # 'LicenseName'
    # 'Photographer'
  end

  # Validar si texto es una URL, si lo es, regresa la liga en HTML, si no, regresa el mismo texto
  def es_url_valido(text)
    begin
      url = URI.parse(text.to_s)
      url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS) ? resultado = "<a target='_blank' href='#{text}'>#{text}</a>".html_safe : resultado = text
     rescue
      resultado = text
    end
    resultado
  end

  def dejaComentario
    link_to("comentario, sugerencia o corrección <span class='glyphicon glyphicon-comment'></span>".html_safe, new_especie_comentario_path(@especie))
  end

end
