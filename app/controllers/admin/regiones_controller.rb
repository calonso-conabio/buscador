class Admin::RegionesController < Admin::AdminController
  before_action :set_admin_region, only: [:show, :edit, :update, :destroy]

  # GET /admin/regiones
  # GET /admin/regiones.json
  def index
    @admin_regiones = Admin::Region.all
  end

  # GET /admin/regiones/1
  # GET /admin/regiones/1.json
  def show
  end

  # GET /admin/regiones/new
  def new
    @admin_region = Admin::Region.new
  end

  # GET /admin/regiones/1/edit
  def edit
  end

  # POST /admin/regiones
  # POST /admin/regiones.json
  def create
    @admin_region = Admin::Region.new(admin_region_params)

    respond_to do |format|
      if @admin_region.save
        format.html { redirect_to @admin_region, notice: 'Region was successfully created.' }
        format.json { render :show, status: :created, location: @admin_region }
      else
        format.html { render :new }
        format.json { render json: @admin_region.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/regiones/1
  # PATCH/PUT /admin/regiones/1.json
  def update
    respond_to do |format|
      if @admin_region.update(admin_region_params)
        format.html { redirect_to @admin_region, notice: 'Region was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin_region }
      else
        format.html { render :edit }
        format.json { render json: @admin_region.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/regiones/1
  # DELETE /admin/regiones/1.json
  def destroy
    @admin_region.destroy
    respond_to do |format|
      format.html { redirect_to admin_regiones_url, notice: 'Region was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /admin/regiones/autocompleta?q=
  def autocompleta
    regiones = params[:term].present? ? Admin::Region.autocompleta(params[:term]) : []
    render json: regiones.map { |b| { label: "#{b.nombre_region}, #{b.tipo_region.descripcion}", value: b.id } }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_region
      @admin_region = Admin::Region.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_region_params
      params.require(:admin_region).permit(:nombre_region, :tipo_region_id, :clave_region, :id_region_asc)
    end
end
