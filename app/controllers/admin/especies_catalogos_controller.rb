class Admin::EspeciesCatalogosController < Admin::AdminController
  before_action :set_admin_especie_catalogo, only: [:show, :edit, :update, :destroy]

  # GET /admin/especies_catalogos
  # GET /admin/especies_catalogos.json
  def index
    @admin_especies_catalogos = Admin::EspecieCatalogo.all
  end

  # GET /admin/especies_catalogos/1
  # GET /admin/especies_catalogos/1.json
  def show
  end

  # GET /admin/especies_catalogos/new
  def new
    @admin_especie_catalogo = Admin::EspecieCatalogo.new
  end

  # GET /admin/especies_catalogos/1/edit
  def edit
  end

  # POST /admin/especies_catalogos
  # POST /admin/especies_catalogos.json
  def create
    @admin_especie_catalogo = Admin::EspecieCatalogo.new(admin_especie_catalogo_params)

    respond_to do |format|
      if @admin_especie_catalogo.save
        format.html { redirect_to @admin_especie_catalogo, notice: 'Especie catalogo was successfully created.' }
        format.json { render :show, status: :created, location: @admin_especie_catalogo }
      else
        format.html { render :new }
        format.json { render json: @admin_especie_catalogo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/especies_catalogos/1
  # PATCH/PUT /admin/especies_catalogos/1.json
  def update
    respond_to do |format|
      if @admin_especie_catalogo.update(admin_especie_catalogo_params)
        format.html { redirect_to @admin_especie_catalogo, notice: 'Especie catalogo was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin_especie_catalogo }
      else
        format.html { render :edit }
        format.json { render json: @admin_especie_catalogo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/especies_catalogos/1
  # DELETE /admin/especies_catalogos/1.json
  def destroy
    @admin_especie_catalogo.destroy
    respond_to do |format|
      format.html { redirect_to admin_especies_catalogos_url, notice: 'Especie catalogo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_especie_catalogo
      @admin_especie_catalogo = Admin::EspecieCatalogo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_especie_catalogo_params
      params.require(:admin_especie_catalogo).permit(:especie_id, :catalogo_id, :observaciones)
    end
end
