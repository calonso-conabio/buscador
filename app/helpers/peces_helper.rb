module PecesHelper

  # Se duplico para utilizarla solo en los resultados, ya que rata de hacer el join con adicionales para cada uno de los peces #facepalm!! >.>! ¬.¬
  def tituloNombreCientificoPeces(taxon, params={})
    nombre = taxon.nombre_comun_principal.try(:capitalize)

    if params[:title]
      nombre.present? ? "#{nombre} (#{taxon.nombre_cientifico})".html_safe : taxon.nombre_cientifico
    elsif params[:link]
      nombre.present? ? "<h5>#{nombre}</h5><h5>#{link_to(ponItalicas(taxon).html_safe, especie_path(taxon))}</h5>" : "<h5>#{ponItalicas(taxon,true)}</h5>"
    elsif params[:show]
      nombre.present? ? "#{nombre} (#{ponItalicas(taxon)})".html_safe : ponItalicas(taxon).html_safe
    else
      'Ocurrio un error en el nombre'.html_safe
    end
  end

  def checkboxGruposIconicos
    checkBoxes = ''
    grupos = params[:grupos_iconicos] || []

    @grupos.each do |taxon|  # Para tener los grupos ordenados
      checkBoxes << "<label>"
      checkBoxes << check_box_tag('grupos_iconicos[]', taxon.id, grupos.include?(taxon.id.to_s), id: "grupos_iconicos_#{taxon.id}")
      checkBoxes << "<span title = '#{taxon.nombre_comun_principal}' class = 'btn-title #{taxon.nombre_cientifico.parameterize}-ev-icon'>"
      checkBoxes << "</span>"
      checkBoxes << "</label>"
    end

    checkBoxes.html_safe
  end

  def checkboxSemaforo
    checkBoxes = ''
    s = {:v => ['Recomendable','semaforo-recomendable'], :a => ['Poco recomendable','semaforo-moderado'], :r => ['Evita','semaforo-evita'], :star => ['Pesquerías que hacen esfuerzos para ser sustentables','certificacion'], :sn => ['Especies sin datos','semaforo-no-datos']}
    seleccionados = params[:semaforo_recomendacion] || []

    s.each do |k,v|
      checkBoxes << "<label>"
      checkBoxes << check_box_tag('semaforo_recomendacion[]', k, seleccionados.include?(k.to_s), id: "semaforo_recomendacion_#{v[0].parameterize}")
      checkBoxes << "<span title = '#{v[0]}' class = 'btn-zona-#{k} btn-title'>"
      checkBoxes << "<i class = '#{v[1]}-ev-icon'></i>"
      checkBoxes << "</span>"
      checkBoxes << "</label>"
    end

    checkBoxes.html_safe
  end

  def checkboxCriteriosPeces(cat, ico=false, titulo=false)
    checkBoxes= titulo ? "<h4><strong>#{titulo}</strong></h5>" : ""

    cat.each do |k, valores|
      filtros = params[k] || []
      valores.each do |edo, id|
        edo_p = edo.parameterize
        next if edo_p == 'sin-datos' || edo_p == 'no-aplica'
        checkBoxes << "<label class = '#{k}'>"
        checkBoxes << check_box_tag("#{k}[]", id, filtros.include?(id.to_s), :id => "#{k}_#{edo_p}")
        checkBoxes << "<span title = '#{edo}' class = '#{'btn-title' if ico}'>"
        checkBoxes << "<b>#{edo}</b>" unless ico
        checkBoxes << "<i class='#{edo_p}-ev-icon'></i>" if ico
        checkBoxes << "</span>"
        checkBoxes << "</label>"
      end
    end
    checkBoxes.html_safe
  end

  def dibujaZonasPez(c, i)
    lista = ''
    lista << "<span class='btn-zona btn-zona-#{@pez.valor_zonas[i]}' tooltip-title='#{c[:nombre]}'>"
    lista << "<i class = '#{valorAIcono(@pez[:valor_zonas][i])}-ev-icon'></i>"
    lista << "<b>#{c[:tipo_propiedad]}</b>"
    lista << "</span>"
    lista
  end

  def muestraCertificacion
    html = ''

    @pez.criterio_propiedades.pesquerias.each do |p|
      html << link_to('<i class="certificacion-ev-icon"></i>'.html_safe, "http://comepesca.com/conoce-comepesca/#directorio-comercial", target: '_blank', class: 'btn btn-xs btn-basica btn-zona-star btn-title')
      html << "<em class='popover-certificacion'><strong>#{p.nombre_propiedad}</strong><br /><small>#{p.descripcion}</small></em>"
    end

    html
  end

  def filtrosUsados
    filtros_usados = ''

    ###
    grupos = params[:grupos_iconicos] || []
    @grupos.each do |taxon|  # Para tener los grupos ordenados
      filtros_usados << "<span title = '#{taxon.nombre_comun_principal}' class = 'btn-title'><i class = '#{taxon.nombre_cientifico.parameterize}-ev-icon'></i></span>" if grupos.include?(taxon.id.to_s)
    end

    ###
    seleccionados = params[:semaforo_recomendacion] || []
    s = {:v => ['Recomendable','semaforo-recomendable'], :a => ['Poco recomendable','semaforo-moderado'], :r => ['Evita','semaforo-evita'], :star => ['Pesquerías que hacen esfuerzos para ser sustentables','certificacion'], :sn => ['Especies sin datos','semaforo-no-datos']}
    s.each do |k,v|
      filtros_usados << "<span title = '#{v[0]}' class = 'btn-title'><i class = 'btn-zona btn-zona-#{k} #{v[1]}-ev-icon'></i></span>" if seleccionados.include?(k.to_s)
    end
    ###

    [:zonas, :nom, :iucn, :tipo_vedas, :tipo_capturas, :procedencias, :cnp].each do |f|
      filtros = params[f] || []

      case f
      when :zonas, :cnp
        @filtros[f].each do |edo, id|
          edo_p = edo.parameterize
          next if edo_p == 'sin-datos' || edo_p == 'no-aplica'
          if filtros.include?(id.to_s)
            filtros_usados << "<i title = '#{edo}' class = '#{f} btn-title btn-default'>#{edo}</i>"
          end
        end
      when :nom, :iucn
        @filtros[f].map{|k| [k.nombre_propiedad, k.id]}.each do |edo, id|
          edo_p = edo.parameterize
          next if edo_p == 'sin-datos' || edo_p == 'no-aplica'
          if filtros.include?(id.to_s)
            filtros_usados << "<span title = '#{edo}' class = 'btn-title'><i class = '#{f} #{edo_p}-ev-icon'></i></span>"
          end
        end
      else
        @filtros[f].map{|k| [k.nombre_propiedad, k.id]}.each do |edo, id|
          edo_p = edo.parameterize
          next if edo_p == 'sin-datos' || edo_p == 'no-aplica'
          if filtros.include?(id.to_s)
            filtros_usados << "<i title = '#{edo}' class = '#{f} btn-title btn-default'>#{edo}</i>"
          end
        end
      end
    end

    ###

    grupo = params[:grupos] || ''
    @filtros[:grupos].each do |g|
      if g.id == grupo.to_i
        filtros_usados << "<span title='Grupo seleccionado' class='btn-title'><i class='label label-primary'>#{g.nombre_propiedad}</i></span>"
        break
      end
    end

    filtros_usados << "<span title='Taxón seleccionado' class='btn-title'><i class='label label-primary'>#{params[:nombre]}</i></span>" if params[:nombre].present?


    filtros_usados
  end

  def valorAColor valor
    color = case valor
            when -10..4 then "v"
            when 5..19 then "a"
            else "r"
            end
    color
  end

  def valorAIcono valor
    clase = case valor
            when "v" then "semaforo-recomendable"
            when "a" then "semaforo-moderado"
            when "r" then "semaforo-evita"
            when "s" then "semaforo-no-datos"
            when "n" then "block"
            else ""
            end
    clase
  end

end
