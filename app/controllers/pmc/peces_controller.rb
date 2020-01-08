class Pmc::PecesController < Pmc::PmcController

  before_action do
    @no_render_busqueda_basica = true
  end

  before_action :set_pez, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_usuario!, :except => [:show, :index, :dameNombre]
  before_action :only => [:new, :update, :edit, :create, :destroy] do
    tiene_permiso?('AdminPeces', true)  # Minimo administrador... de peces duh!
  end

  # Busqueda por pez y marisco
  def index
    if params[:commit].present?
      @filtros =  Pmc::Criterio.dame_filtros
      @grupos = Especie.select_grupos_iconicos.where(nombre_cientifico: Pmc::Pez::GRUPOS_PECES_MARISCOS).order("FIELD(`#{CONFIG.bases.cat}`.`Nombre`.`NombreCompleto`, '#{Pmc::Pez::GRUPOS_PECES_MARISCOS.join("','")}')")
      @peces = Pmc::Pez.filtros_peces

      if params[:id].present?  # Busqueda cuando selecciono un nombre en redis
        @peces = @peces.where(especie_id: params[:id])
      elsif params[:nombre].present? # Busqueda por nombre científico o comunes
        @peces = @peces.where("LOWER(nombres_comunes) REGEXP ? OR LOWER(#{Especie.attribute_alias(:nombre_cientifico)}) REGEXP ?", params[:nombre].downcase, params[:nombre].downcase)
      end

      # Busqueda con pesquerias
      @peces = @peces.where(especie_id: params[:pesquerias]) if params[:pesquerias].present?

      # Filtros globales
      @peces = @peces.where("peces_propiedades.propiedad_id = ?", params[:grupos]) if params[:grupos].present?
      @peces = @peces.where("criterios.id IN (#{params[:tipo_capturas].join(',')})") if params[:tipo_capturas].present?
      @peces = @peces.where("criterios.id IN (#{params[:tipo_vedas].join(',')})") if params[:tipo_vedas].present?
      @peces = @peces.where("criterios.id IN (#{params[:procedencias].join(',')})") if params[:procedencias].present?
      @peces = @peces.where("criterios.id IN (#{params[:nom].join(',')})") if params[:nom].present?
      @peces = @peces.where("criterios.id IN (#{params[:iucn].join(',')})") if params[:iucn].present?
      @peces = @peces.where("criterios.id IN (#{params[:cnp].join(',')})") if params[:cnp].present?

      # Filtro de grupo iconico
      if params[:grupos_iconicos].present? && params[:grupos_iconicos].any?
        ids = params[:grupos_iconicos].map{ |id| ",#{id}," }
        @peces = @peces.where("#{Especie.table_name}.#{Especie.attribute_alias(:ancestry_ascendente_directo)} REGEXP '#{ids.join('|')}'")
      end

      # La asigno aqui para que se encuentre más abajo
      recomendacion = params[:semaforo_recomendacion]

      # Busqueda con estrella
      if params[:semaforo_recomendacion].present? && params[:semaforo_recomendacion].include?('star')
        @peces = @peces.where(con_estrella: 1)
        recomendacion = params[:semaforo_recomendacion]-['star']  # Quito este valor, para que no busque con expresiones regualres "star"
      end

      # Filtros del SEMAFORO de RECOMENDACIÓN
      if recomendacion.present? && params[:zonas].present?
        regexp = dame_regexp_zonas(zonas: params[:zonas], color_seleccionado: "[#{recomendacion.join('')}]")
        @peces = @peces.where("valor_zonas REGEXP '#{regexp}'")
      elsif recomendacion.present?
        # Selecciono el valor de sin datos
        if recomendacion.include?('sn')
          rec = "[#{recomendacion.join('')}]{6}"
        else # Cualquier otra combinacion
          rec = recomendacion.map{ |r| r.split('') }.join('|')
        end
        @peces = @peces.where("valor_zonas REGEXP '#{rec}'")
      elsif params[:zonas].present?
        regexp = dame_regexp_zonas(zonas: params[:zonas])
        @peces = @peces.where("valor_zonas REGEXP '#{regexp}'")
      end

      render 'resultados'
    else
      redirect_to '/pmc/peces?semaforo_recomendacion%5B%5D=star&commit=Buscar'
    end
  end

  def show
    criterios = @pez.criterio_propiedades.select('*, valor').order(:ancestry)
    @criterios = acomoda_criterios(criterios)
    respond_to do |format|
      if params[:mini].present?
        @zonas = Pmc::Propiedad.zonas
        render :partial => 'mini_show' and return
      end
      format.html # show.html.erb
      format.json { render json: {pez: @pez, criterios: @criterios}.to_json }
    end
  end

  # GET /peces/new
  def new
    @form_params = { url: '/pmc/peces', method: 'post' }
    @pez = Pmc::Pez.new
  end

  # GET /peces/1/edit
  def edit
    @form_params = {}
  end

  # POST /peces
  def create
    @pez = Pmc::Pez.new(pez_params)

    if @pez.save
      redirect_to pmc_pez_path(@pez), notice: 'El pez fue creado satisfactoriamente.'
    else
      @form_params = { url: '/pmc/peces', method: 'post' }
      render action: 'new'
    end
  end

  # PATCH/PUT /peces/1
  def update
    if @pez.update_attributes(pez_params)
      redirect_to @pez, notice: 'El Pez fue actualizado satisfactoriamente.'
    else
      render action: 'edit'
    end
  end

  # DELETE /peces/1
  def destroy
    @pez.destroy
    redirect_to '/pmc/peces', notice: 'El pez fue destruido satisfactoriamente.'
  end

  def dameNombre
    tipo = params[:tipo]
    case tipo
    when 'cientifico'
      render json: Pmc::Pez.nombres_cientificos_peces.where("nombre_cientifico LIKE ?", "%#{params[:term]}%").to_json
    when 'comunes'
      render json: Pmc::Pez.nombres_comunes_peces.where("nombres_comunes LIKE ?", "%#{params[:term]}%").to_json
    else
      render json: [{error: 'no encontre'}].to_json
    end
  end


  private

  # Use callbacks to share common setup or constraints between actions.
  def set_pez
    @pez = Pmc::Pez.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def pez_params
    params.require(:pmc_pez).permit(:especie_id, :veda_fechas, :nombre, peces_criterios_attributes: [:id, :criterio_id, :_destroy],
                                    peces_propiedades_attributes: [:id, :propiedad_id, :_destroy])
  end

  def dame_regexp_zonas(opc = {})
    colores_default = opc[:colores_default] || '[varns]'
    color_seleccionado = opc[:color_seleccionado] || '[var]'
    valor_por_zona = Array.new(6, colores_default)
    opc[:zonas].each do |z|
      valor_por_zona[z.to_i] = color_seleccionado
    end
    valor_por_zona.join('')
  end

  def acomoda_criterios(criterios_obj)
    criterios = {}
    criterios['Grupo'] = []
    criterios['Características'] = []
    criterios['Estado poblacional en el Pacífico'] = []
    criterios['Estado poblacional en el Golfo de México y caribe'] = []
    criterios['suma_caracteristicas'] = 0
    criterios['otros'] = {}

    criterios_obj.each do |c|

      dato = {}
      dato[:nombre] = c.nombre_propiedad
      dato[:valor] = c.valor
      dato[:tipo_propiedad] = c.tipo_propiedad
      dato[:ancestry] = c.ancestry

      case c.ancestry
      when Pmc::Propiedad::NOM_ID.to_s
        nombre_prop = c.nombre_propiedad.estandariza
        criterios['suma_caracteristicas']+= c.valor
        dato[:icono] = "#{nombre_prop}-ev-icon" if nombre_prop != 'no-aplica'
        criterios['Características'][0] = dato
      when Pmc::Propiedad::IUCN_ID.to_s
        nombre_prop = c.nombre_propiedad.estandariza
        criterios['suma_caracteristicas']+= c.valor
        dato[:icono] = "#{nombre_prop}-ev-icon" if nombre_prop != 'no-aplica'
        criterios['Características'][1] = dato
      when Pmc::Propiedad::TIPO_CAPTURA_ID.to_s
        criterios['suma_caracteristicas']+= c.valor
        criterios['Características'][2] = dato
      when Pmc::Propiedad::TIPO_DE_VEDA_ID.to_s
        criterios['suma_caracteristicas']+= c.valor

        if Pmc::Criterio::CON_ADVERTENCIA.include?(c.nombre_propiedad)
          dato[:advertencia] = 'glyphicon glyphicon-exclamation-sign'
        end

        criterios['Características'][3] = dato
      when Pmc::Propiedad::PROCEDENCIA_ID.to_s
        criterios['suma_caracteristicas']+= c.valor

        if Pmc::Criterio::CON_ADVERTENCIA.include?(c.nombre_propiedad)
          dato[:advertencia] = 'glyphicon glyphicon-exclamation-sign'
        end

        criterios['Características'][4] = dato

      when Pmc::Propiedad::ZONAI
        criterios['Estado poblacional en el Pacífico'][0] = dato
      when Pmc::Propiedad::ZONAII
        criterios['Estado poblacional en el Pacífico'][1] = dato
      when Pmc::Propiedad::ZONAIII
        criterios['Estado poblacional en el Pacífico'][2] = dato
      when Pmc::Propiedad::ZONAIV
        criterios['Estado poblacional en el Golfo de México y caribe'][0] = dato
      when Pmc::Propiedad::ZONAV
        criterios['Estado poblacional en el Golfo de México y caribe'][1] = dato
      when Pmc::Propiedad::ZONAVI
        criterios['Estado poblacional en el Golfo de México y caribe'][2] = dato
      else
        if criterios['otros'][c.ancestry[0..6]]
          criterios['otros'][c.ancestry[0..6]] << dato
        else
          criterios['otros'][c.ancestry[0..6]] = [dato]
        end
      end  # End case
    end  # End each criterios

    criterios
  end
end
