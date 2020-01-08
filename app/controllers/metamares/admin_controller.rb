class Metamares::AdminController < Metamares::MetamaresController

  before_action :authenticate_metausuario!
  before_action  do
    tiene_permiso?('AdminInfoceanos')  # Minimo administrador
  end

  before_action :set_usuario, only: [:edit, :update]

  def index
    @usuarios = Usuario.select(:id, :nombre, :apellido, :email).select('nombre_rol').left_joins(:usuario_roles, :roles).
        where("usuarios_roles.rol_id IN (#{Rol::METAMARES_ROLES.map{|r| r.to_s.to_i}.join(',')})").order(:id).uniq
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    @estatuse = Estatus.new(estatuse_params)

    respond_to do |format|
      if @estatuse.save
        format.html { redirect_to @estatuse, notice: 'Estatus was successfully created.' }
        format.json { render action: 'show', status: :created, location: @estatuse }
      else
        format.html { render action: 'new' }
        format.json { render json: @estatuse.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @usuario.update(usuario_params)
        format.html { redirect_to metamares_admin_index_path, notice: 'El usuario se actualizó correctamente' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @estatuse.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @estatuse.destroy
    respond_to do |format|
      format.html { redirect_to estatuses_url }
      format.json { head :no_content }
    end
  end


  private

  def usuario_params
    params.require(:usuario).permit(:nombre, :apellido, :email, :institucion, :password, :password_confirmation,
                                    usuario_roles_attributes: [:id, :usuario_id, :rol_id, :done, :_destroy])
  end

  def set_usuario
    begin
      @usuario = Usuario.find(params[:id])
    rescue
      render :_error and return
    end
  end

end
