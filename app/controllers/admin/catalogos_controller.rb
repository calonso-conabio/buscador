class Admin::CatalogosController < Admin::AdminController

  before_action do
    @no_render_busqueda_basica = true
  end

  before_action :set_admin_catalogo, only: [:show, :edit, :update, :destroy]

  # GET /admin/catalogos
  # GET /admin/catalogos.json
  def index
    @admin_catalogo = Admin::Catalogo.new(admin_catalogo_index)
    @admin_catalogos = @admin_catalogo.query_index
  end

  # GET /admin/catalogos/1
  # GET /admin/catalogos/1.json
  def show
  end

  # GET /admin/catalogos/new
  def new
    @form_params = { url: '/admin/catalogos', method: 'post' }
    @admin_catalogo = Admin::Catalogo.new
  end

  # GET /admin/catalogos/1/edit
  def edit
    @form_params = {}
    @admin_catalogo = Admin::Catalogo.includes(especies_catalogo: [:especie, bibliografias: :bibliografia, regiones: [region: [:tipo_region], bibliografias: :bibliografia]]).where(id: params[:id]).first
  end

  # POST /admin/catalogos
  # POST /admin/catalogos.json
  def create
    @admin_catalogo = Admin::Catalogo.new(admin_catalogo_params)

    respond_to do |format|
      if @admin_catalogo.save
        format.html { redirect_to @admin_catalogo, notice: 'Catalogo was successfully created.' }
        format.json { render action: 'show', status: :created, location: @admin_catalogo }
      else
        format.html { render action: 'new' }
        format.json { render json: @admin_catalogo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/catalogos/1
  # PATCH/PUT /admin/catalogos/1.json
  def update
    respond_to do |format|
      if @admin_catalogo.update(admin_catalogo_params)
        format.html { redirect_to @admin_catalogo, notice: 'Catalogo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @admin_catalogo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/catalogos/1
  # DELETE /admin/catalogos/1.json
  def destroy
    @admin_catalogo.destroy
    respond_to do |format|
      format.html { redirect_to catalogos_url }
      format.json { head :no_content }
    end
  end

  # El ajax cuando edita los niveles de una catalogo
  def dame_nivel
    nivel = params[:nivel]
    if nivel.present? && (0..5).to_a.include?(nivel.to_i)
      admin_catalogo = Admin::Catalogo.new(admin_catalogo_niveles_params)
      admin_catalogo.ajax = true
      render json: { estatus: true, resultados: admin_catalogo.send("dame_nivel#{nivel.to_i + 1}") }
    else
      render json: { estatus: false, msg: 'Parámetros incorrecto' }
    end
  end


  private

  # Use callbacks to share common setup or constraints between actions.
  def set_admin_catalogo
    @admin_catalogo = Admin::Catalogo.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def admin_catalogo_params
    p = params.require(:admin_catalogo).permit(:descripcion, :nivel1, :nivel2, :nivel3, :nivel4, :nivel5, especies_catalogo_attributes: [:id, :especie_id, :catalogo_id, :_destroy, bibliografias_attributes: [:id, :especie_id, :catalogo_id, :bibliografia_id, :_destroy], regiones_attributes: [:id, :especie_id, :catalogo_id, :region_id, :_destroy, bibliografias_attributes: [:id, :especie_id, :catalogo_id, :region_id, :bibliografia_id, :_destroy]]])
    separa_multiples_llaves_foraneas(p)
  end

  # Para que pueda seguir guardando con el comportamiento de cocoon con multiples llaves foráneas
  def separa_multiples_llaves_foraneas(p)
    atributos = %w(especies_catalogo_attributes)

    # atributos del nivel 1 de anidamiento
    atributos.each do |atributo|
      next unless p.key?(atributo)

      # Iterando cada elemento especie_catalogo
      p[atributo].each do |k,v|
        next unless v["id"].present?
        next unless v["catalogo_id"].present?
        next unless v["especie_id"].present?
        v["id"] = [v["catalogo_id"], v["especie_id"]]

        # Iterando cada elemento especie_catalogo_bibliografia
        if v["bibliografias_attributes"].present?
          v["bibliografias_attributes"].each do |kbiblio, biblio|
            next unless biblio.present?
            next unless biblio["id"].present?
            next unless biblio["catalogo_id"].present?
            next unless biblio["especie_id"].present?
            next unless biblio["bibliografia_id"].present?
            biblio["id"] = [biblio["catalogo_id"], biblio["especie_id"], biblio["bibliografia_id"]]
          end
        end

        # Iterando cada elemento especie_catalogo_region
        if v["regiones_attributes"].present?
          v["regiones_attributes"].each do |kregion, region|
            next unless region.present?
            next unless region["id"].present?
            next unless region["catalogo_id"].present?
            next unless region["especie_id"].present?
            next unless region["region_id"].present?
            region["id"] = [region["catalogo_id"], region["especie_id"], region["region_id"]]

            # Iterando cada elemento especie_catalogo_region_bibliografia
            if region["bibliografias_attributes"].present?
              region["bibliografias_attributes"].each do |kbiblio, biblio|
                next unless biblio.present?
                next unless biblio["id"].present?
                next unless biblio["catalogo_id"].present?
                next unless biblio["especie_id"].present?
                next unless biblio["region_id"].present?
                next unless biblio["bibliografia_id"].present?
                biblio["id"] = [biblio["catalogo_id"], biblio["especie_id"], biblio["region_id"], biblio["bibliografia_id"]]
              end
            end
          end
        end
      end
    end

    p
  end

  # La lista blanca para el ajax cuando edita los niveles de una catalogo
  def admin_catalogo_niveles_params
    params.permit(:nivel1, :nivel2, :nivel3, :nivel4, :nivel5)
  end

  # La lista blanca para los filtros de especie y nivel1
  def admin_catalogo_index
    begin
      params.require(:admin_catalogo).permit(:especie_id, :nivel1)
    rescue
      {}
    end
  end

end
