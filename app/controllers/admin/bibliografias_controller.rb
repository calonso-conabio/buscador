class Admin::BibliografiasController < Admin::AdminController

  before_action :set_admin_bibliografia, only: [:show, :edit, :update, :destroy]

  # GET /admin/bibliografias
  # GET /admin/bibliografias.json
  def index
    @admin_bibliografias = Admin::Bibliografia.all
  end

  # GET /admin/bibliografias/1
  # GET /admin/bibliografias/1.json
  def show
  end

  # GET /admin/bibliografias/new
  def new
    @admin_bibliografia = Admin::Bibliografia.new
  end

  # GET /admin/bibliografias/1/edit
  def edit
  end

  # POST /admin/bibliografias
  # POST /admin/bibliografias.json
  def create
    @admin_bibliografia = Admin::Bibliografia.new(admin_bibliografia_params)

    respond_to do |format|
      if @admin_bibliografia.save
        format.html { redirect_to @admin_bibliografia, notice: 'Bibliografia was successfully created.' }
        format.json { render :show, status: :created, location: @admin_bibliografia }
      else
        format.html { render :new }
        format.json { render json: @admin_bibliografia.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/bibliografias/1
  # PATCH/PUT /admin/bibliografias/1.json
  def update
    respond_to do |format|
      if @admin_bibliografia.update(admin_bibliografia_params)
        format.html { redirect_to @admin_bibliografia, notice: 'Bibliografia was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin_bibliografia }
      else
        format.html { render :edit }
        format.json { render json: @admin_bibliografia.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/bibliografias/1
  # DELETE /admin/bibliografias/1.json
  def destroy
    @admin_bibliografia.destroy
    respond_to do |format|
      format.html { redirect_to admin_bibliografias_url, notice: 'Bibliografia was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /admin/bibliografias/autocompleta?q=
  def autocompleta
    bibliografias = params[:term].present? ? Admin::Bibliografia.autocompleta(params[:term]) : []
    render json: bibliografias.map { |b| { label: b.cita_completa, value: b.id } }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_bibliografia
      @admin_bibliografia = Admin::Bibliografia.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_bibliografia_params
      params.require(:admin_bibliografia).permit(:autor, :anio, :titulo_publicacion, :titulo_sub_publicacion, :editorial_pais_pagina, :numero_volumen_anio, :editores_compiladores, :isbnissn, :observaciones)
    end

end
