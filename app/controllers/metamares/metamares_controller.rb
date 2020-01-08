class Metamares::MetamaresController < ApplicationController
  layout 'metamares'

  #la pagina de flopez
  def index
    #render layout: false
    @doc = Nokogiri::HTML(open("https://www.biodiversidad.gob.mx/pais/mares/infoceanos/")).css('#project')
    @doc.css('#pagetitle').remove
    @doc.css('#sectionmenu').remove
    @doc.css('#pageima').remove
    @doc.xpath('//comment()').remove

    @doc.each do |el|
      el.traverse do |n|
        next if n.key?('id') && %w(accordion collapse1 collapse2 collapse3 collapse4).include?(n.attribute('id').value)
        n.remove_attribute('id')
        n.remove_class('contenidoGRALima')
        n.remove_class('project')
        if n.matches?('img')
          n.attribute('src').value = n.attribute('src').value.gsub('../../../', 'https://www.biodiversidad.gob.mx/')
        end
      end
    end

    @doc = @doc.to_html.encode("utf-8")
  end

  # La visualizacion por medio de D3
  def graficas
  end

  # Gráfica por año de publicacion contra campo de investigación
  def grafica1
    g = Metamares::GraficasM.new
    g.grafica1

    render json: g.datos
  end

  # Gráfica por área, region o localidad
  def grafica2
    g = Metamares::GraficasM.new(tipo_dato: [])
    g.grafica2

    render json: g.datos
  end

  # Busca una institucion por slug
  def dame_institucion
    i = Metamares::Institucion.new
    i.nombre_institucion = params[:nombre_institucion]

    respond_to do |format|
      format.json { render json: i.busca_institucion.map{ |i| { id: i.id, value: i.nombre_institucion } } }
      format.html { @institucion = i }
    end
  end

  # Busca un keyword por slug
  def dame_keyword
    k = Metamares::Keyword.new
    k.nombre_keyword = params[:nombre_keyword]

    respond_to do |format|
      format.json { render json: k.busca_keyword.map{ |k| { id: k.nombre_keyword, value: k.nombre_keyword } } }
      format.html { @keyword = k }
    end
  end

  protected

  def tiene_permiso?(nombre_rol, con_hijos=false)
    render 'shared/sin_permiso' and return unless metausuario_signed_in? #con esto aseguramos que el usuario ya inicio sesión
    roles_usuario = current_metausuario.usuario_roles.map(&:rol)
    #Si se es superusuario o algun otro tipo de root, entra a ALL
    return if roles_usuario.map(&:depth).any?{|d| d < 1}
    rol = Rol.find_by_nombre_rol(nombre_rol)
    #Si solicito vástagos, entonces basta con ser hijo del mínimo requerido:
    return if con_hijos && roles_usuario.map(&:path_ids).flatten.include?(rol.id)
    #Si no requiero vastagos revisa si el nombre_rol pertenece al linaje (intersección del subtree_ids del usuario y del rol)
    render 'shared/sin_permiso' unless rol.present? && (roles_usuario.map(&:subtree_ids).flatten & rol.path_ids).any?
  end

  def es_propietario?(obj)
    return false unless metausuario_signed_in?
    usuario_id = obj.usuario_id
    current_metausuario.id == usuario_id
  end

end
