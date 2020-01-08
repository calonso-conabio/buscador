class Fichas::TaxaController < Fichas::FichasController
  before_action :set_taxon, only: [:show, :edit, :update, :destroy]

  # GET /taxa
  # GET /taxa.json
  def index
    @taxa = Taxon.all
  end

  # GET /taxa/1
  # GET /taxa/1.json
  def show
  end

  # GET /taxa/new
  def new
    @taxon = Taxon.new
  end

  # GET /taxa/1/edit
  def edit
    @form_params = { url: '/fichas/taxa', method: 'post' }
  end

  # POST /taxa
  # POST /taxa.json
  def create
    @taxon = Fichas::Taxon.new(taxon_params)

    respond_to do |format|
      if @taxon.save
        format.html { redirect_to @taxon, notice: 'Taxon was successfully created.' }
        format.json { render :show, status: :created, location: @taxon }
      else
        format.html { render :new }
        format.json { render json: @taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /taxa/1
  # PATCH/PUT /taxa/1.json
  def update
    respond_to do |format|
      if @taxon.update(taxon_params)
        format.html { redirect_to @taxon, notice: 'Taxon was successfully updated.' }
        format.json { render :show, status: :ok, location: @taxon }
      else
        format.html { render :edit }
        format.json { render json: @taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /taxa/1
  # DELETE /taxa/1.json
  def destroy
    @taxon.destroy
    respond_to do |format|
      format.html { redirect_to taxa_url, notice: 'Taxon was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_taxon
      @taxon = Fichas::Taxon.where(IdCat: params[:id]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def taxon_params
      params.fetch(:taxon, {})
    end
end
