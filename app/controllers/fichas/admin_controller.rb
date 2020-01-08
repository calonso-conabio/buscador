class Fichas::AdminController < Fichas::FichasController

  before_action :set_ficha, only: [:edit, :update, :show, :destroy]
  # layout false

  def edit
    @form_params = { url: '/fichas/admin', method: 'post' }
  end

  def show # Redireccionar a la vista front de la ficha
    redirect_to "http://#{IP}:#{PORT}fichas/front/#{params[:id]}"
  end

  def create


  end

  def update

  end

  def set_ficha
    begin
      @taxon = Fichas::Taxon.where(IdCat: params[:id]).first
    rescue
      render :_error and return
    end
  end

end