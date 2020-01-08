module ApplicationHelper
  def bitacora
    if usuario_signed_in?
      if Rol::CON_BITACORA.include?(current_usuario.rol_id)
        desc=''
        Bitacora.order('id DESC').limit(10).each do |bitacora|
          desc+= "<li>#{bitacora.usuario.usuario} #{bitacora.descripcion}</li>"
        end

        if desc.present?
          bitacora = "<br><br><table class=\"tabla_formato\"><tr><td><fieldset><legend class=\"leyenda\">Bitácora</legend>"
          bitacora+= "<ul>#{desc}</ul>"
          bitacora+= '</fieldset></td></tr></table>'
        end
      end
    end
  end

  def cite(citation = nil, &block)
    @_citations ||= []
    if citation.blank? && block_given?
      citation = capture(&block)
    end
    citations = [citation].flatten
    links = citations.map do |c|
      #c = c.citation if c.is_a?(Source)    #para no implementar la tabla sources
      @_citations << c unless @_citations.include?(c)
      i = @_citations.index(c) + 1
      link_to(i, "#ref#{i}", :name => "cit#{i}")
    end
    content_tag :sup, links.uniq.sort.join(',').html_safe
  end

  def references(options = {})
    return if @_citations.blank?
    lis = ""
    @_citations.each_with_index do |citation, i|
      lis += if options[:linked]
               l = link_to i+1, "#cit#{i+1}"
               content_tag(:li, "#{l}. #{citation}".html_safe, :class => "reference", :id => "ref#{i+1}")
             else
               content_tag(:li, citation.html_safe, :class => "reference", :id => "ref#{i+1}")
             end
    end
    if options[:linked]
      content_tag :ul, lis.html_safe, :class => "references"
    else
      content_tag :ol, lis.html_safe, :class => "references"
    end
  end

  def formatted_user_text(text, options = {})
    return text if text.blank?

    # make sure attributes are quoted correctly
    text = text.gsub(/(\w+)=['"]([^'"]*?)['"]/, '\\1="\\2"')

    # Make sure P's don't get nested in P's
    text = text.gsub(/<\\?p>/, "\n\n") unless options[:skip_simple_format]
    text = sanitize(text, options)
    text = compact(text, :all_tags => true) if options[:compact]
    text = simple_format(text, {}, :sanitize => false) unless options[:skip_simple_format]
    text = auto_link(text.html_safe, :sanitize => false).html_safe
    # Ensure all tags are closed
    Nokogiri::HTML::DocumentFragment.parse(text).to_s.html_safe
  end

  def serial_id
    @__serial_id = @__serial_id.to_i + 1
    @__serial_id
  end

  def modal_image(photo, options = {})
    size = options[:size]
    img_url ||= photo.best_url(size)
    link_options = options.merge("data-photo-path" => photo_path(photo, :partial => 'photo'))
    link_options[:class] = "#{link_options[:class]} modal_image_link #{size}".strip

    if options[:type] == :pdf
      link_to(
          image_tag(img_url,
                    :title => photo.attribution,
                    :id => "photo_#{photo.id}",
                    :class => "image #{size}"),
          photo.native_page_url,
          link_options
      )
    else
      link_to(
          image_tag(img_url,
                    :title => photo.attribution,
                    :id => "photo_#{photo.id}",
                    :class => "image #{size} img-thumbnail"),
          #image_tag('silk/magnifier.png', :class => 'zoom_icon'),
          #"<span class='glyphicon glyphicon-search' aria-hidden='true'></span>".html_safe,
          photo.native_page_url,
          link_options
      )
    end
  end

  def native_url_for_photo(photo)
    return photo.native_page_url unless photo.native_page_url.blank?
    case photo.class.name
    when "FlickrPhoto"
      "http://flickr.com/photos/#{photo.native_username}/#{photo.native_photo_id}"
    when "LocalPhoto"
      url_for(photo.observations.first)
    else
      nil
    end
  end

  def paginacion(datos)
    sin_page_per_page = datos[:request].split('&').map{|attr| attr if !attr.include?('pagina=')}
    html = "<div class=\"pagination\">"

    # Contiene la secuencias del paginado
    datos[:rangos].each do |d|
      if d.instance_of? String
        case d
        when '← Anterior', 'Siguiente →'
          html << "<span class=\"previous_page disabled\">#{d}</span>"
        when '...'
          html << "<span class=\"gap\">#{d}</span>"
        end
      elsif d.instance_of? Array
        d.each do |pagina|  # Itera el arreglo para poner el link con el numero o solo el numero
          peticion = sin_page_per_page.compact.join('&')

          if pagina == datos[:pagina]
            html << "<em class=\"current\">#{pagina}</em>"
          else
            html << link_to(pagina, peticion << "&por_pagina=#{datos[:por_pagina]}&pagina=#{pagina}")
          end
        end
      end
    end

    html << '</div>'
  end

  def correo_enciclovida claro=nil
    correo_en_fuente = "<span class='enciclovida_correo-ev-icon text-link'></span><span class='glyphicon glyphicon-envelope text-link'></span>"
    correo_en_fuente.gsub!("text-link","text-info") if claro
    link_to(correo_en_fuente.html_safe,"", :onclick => "$(this).attr('href',co.join('').split('').reverse().join(''));", :target => "_blank")
  end

  def imagotipo_naturalista_completo
    "<i class='naturalista-ev-icon'></i><i class='naturalista-2-ev-icon'></i><i class='naturalista-3-ev-icon'></i><i class='naturalista-4-ev-icon'></i>".html_safe
  end

  def imagotipo_naturalista_nombre(tamaño = nil)
    "<i class='naturalista-3-ev-icon'></i><i class='naturalista-4-ev-icon'></i>".html_safe
  end

  def imagotipo_naturalista_app
    "<i class='naturalista-ev-icon'></i><i class='naturalista-2-ev-icon'></i>".html_safe
  end

  def icono_globo
    "<i class='glyphicon glyphicon-globe'></i>".html_safe
  end

  def icono_descarga
    "<i class='glyphicon glyphicon-save'></i>".html_safe
  end

  def tiene_permiso?(nombre_rol, con_hijos=false)
    return false  unless usuario_signed_in? # Con esto aseguramos que el usuario ya inicio sesión
    roles_usuario = current_usuario.usuario_roles.map(&:rol)
    # Si se es superusuario o algun otro tipo de root, entra a ALL
    return true if roles_usuario.map(&:depth).any?{|d| d < 1}
    rol = Rol.find_by_nombre_rol(nombre_rol)
    # Si solicito vástagos, entonces basta con ser hijo del mínimo requerido:
    return true if con_hijos && roles_usuario.map(&:path_ids).flatten.include?(rol.id)
    # Si no requiero vastagos revisa si el nombre_rol pertenece al linaje (intersección del subtree_ids del usuario y del rol)
    return (rol.present? && (roles_usuario.map(&:subtree_ids).flatten & [rol.id]).any?)
  end

  def convierte_a_HTML(text)
    # Verificar si hay información que mostrar
    if text.present?
      # Verificar que sea texto lo que se va a analizar
      if text.is_a? String
        #Asegurar que el fragmento html tenga los "< / >"'s cerrados
        Nokogiri::HTML.fragment(text).to_html.html_safe
      else
        text.to_s
      end
    else
      ''
    end
  end

  def tiene_permiso_metamares?(nombre_rol, con_hijos=false)
    return false  unless metausuario_signed_in? # Con esto aseguramos que el usuario ya inicio sesión
    roles_usuario = current_metausuario.usuario_roles.map(&:rol)
    # Si se es superusuario o algun otro tipo de root, entra a ALL
    return true if roles_usuario.map(&:depth).any?{|d| d < 1}
    rol = Rol.find_by_nombre_rol(nombre_rol)
    # Si solicito vástagos, entonces basta con ser hijo del mínimo requerido:
    return true if con_hijos && roles_usuario.map(&:path_ids).flatten.include?(rol.id)
    # Si no requiero vastagos revisa si el nombre_rol pertenece al linaje (intersección del subtree_ids del usuario y del rol)
    return (rol.present? && (roles_usuario.map(&:subtree_ids).flatten & [rol.id]).any?)
  end

  def es_propietario_metamares?(obj)
    return false unless metausuario_signed_in?
    usuario_id = obj.usuario_id
    current_metausuario.id == usuario_id
  end

end
