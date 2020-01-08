class Metamares::ProyectosController < Metamares::MetamaresController

  before_action :set_proyecto, only: [:edit, :update, :show, :destroy]
  before_action :authenticate_metausuario!, except: [:index, :show]
  before_action except: [:index, :show, :new, :create]  do
    es_propietario?(@proyecto) || tiene_permiso?('AdminInfoceanosManager')
  end

  def index
    busqueda = Metamares::BusquedaProyecto.new
    busqueda.params = proyecto_busqueda_params if params[:proy_b].present?
    busqueda.params[:pagina] = params[:pagina]
    busqueda.sin_limit = params[:commit] == 'Descargar' || params[:commit] == 'JSON'
    busqueda.consulta

    case params[:commit]
    when 'Descargar'
      send_data busqueda.to_csv, filename: "busqueda.csv", disposition: 'attachment', type: :text
    when 'JSON'
      send_data busqueda.to_json, filename: "busqueda.json"
    else
      @proyectos = busqueda.proyectos
      @totales = busqueda.totales
      @pagina = busqueda.pagina
      @paginas = @totales%busqueda.por_pagina == 0 ? @totales/busqueda.por_pagina : (@totales/busqueda.por_pagina) + 1
    end

  end

  def show
  end

  def new
    @proyecto = Metamares::Proyecto.new
  end

  def edit
  end

  def create
    @proyecto = Metamares::Proyecto.new(proyecto_params)

    respond_to do |format|
      if @proyecto.save
        format.html { redirect_to @proyecto, notice: 'El proyecto fue creado satisfactoriamente' }
        format.json { render action: 'show', status: :created, location: @estatuse }
      else
        format.html { render action: 'new' }
        format.json { render json: @proyecto.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @proyecto.update(proyecto_params)
        format.html { redirect_to @proyecto, notice: 'El proyecto fue actualizado satisfactoriamente.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @proyecto.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @proyecto.destroy
    respond_to do |format|
      format.html { redirect_to metamares_proyectos_path }
      format.json { head :no_content }
    end
  end


  private

  def set_proyecto
    begin
      @proyecto = Metamares::Proyecto.find(params[:id])
    rescue
      render :_error and return
    end

  end

  def proyecto_params
    params.require(:metamares_proyecto).permit(:nombre_proyecto, :financiamiento, :tipo_monitoreo, :objeto_monitoreo,
                                               :campo_investigacion, :campo_ciencia, :finalidad, :metodo, :usuario_id, :institucion_id, :autor,
                                               info_adicional_attributes: [:id, :informacion_objeto, :informacion_posterior,
                                                                           :informacion_adicional, :colaboradores,
                                                                           :instituciones_involucradas, :equipo, :comentarios, :_destroy],
                                               periodo_attributes: [:id, :periodicidad, :periodo_monitoreo_desde, :periodo_monitoreo_hasta,
                                                                    :periodo_sistematico_desde, :periodo_sistematico_hasta,
                                                                    :monitoreo_desde, :monitoreo_hasta, :comentarios, :_destroy],
                                               region_attributes: [:id, :nombre_region, :nombre_zona, :nombre_ubicacion, :latitud, :longitud, :poligono,
                                                                   :entidad, :cuenca, :anp, :comentarios, :_destroy],
                                               dato_attributes: [:id, :titulo_conjunto_datos, :titulo_compilacion, :estatus_datos,
                                                                 :resolucion_temporal, :resolucion_espacial, :publicacion_fecha,
                                                                 :descarga_datos, :licencia_uso, :descripcion_base,
                                                                 :metadatos, :publicaciones, :publicacion_url, :descarga_informe,
                                                                 :forma_citar, :notas_adicionales, :restricciones,
                                                                 :numero_ejemplares, :tipo_unidad, :_destroy],
                                               institucion_attributes: [:id, :nombre_institucion, :sitio_web, :contacto,
                                                                        :correo_contacto, :_destroy],
                                               ubicacion_attributes: [:id, :calle_numero, :colonia, :municipio, :ciudad,
                                                                      :entidad_federativa, :cp, :pais, :_destroy],
                                               especies_attributes: [:id, :especie_id, :nombre_cientifico, :proyecto_id, :_destroy],
                                               keywords_attributes: [:id, :nombre_keyword, :proyecto_id, :_destroy]
                                               )
  end

  def proyecto_busqueda_params
    params.require(:proy_b).permit(:proyecto, :institucion, :tipo_monitoreo, :nombre, :especie_id, :tipo_monitoreo, :autor,
                                   :titulo_compilacion, :nombre_zona, :nombre_region, :campo_investigacion, :usuario_id)
  end

end
