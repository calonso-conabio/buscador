class Metamares::Metausuarios::SessionsController < ::Devise::SessionsController
  layout 'metamares'

  private

  def after_sign_in_path_for(resource)
    "/metamares/proyectos"
  end

  def after_sign_out_path_for(resource)
    "/metamares/proyectos"
  end

end
