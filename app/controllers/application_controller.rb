# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_locale#, :authenticate  ##Autentica por credenciales generales
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_header_background

  def to_boolean(str)
    str.downcase == 'true' ? true : false
  end

  def set_locale
    I18n.locale = cookies[:vista].present? ? cookies[:vista] : I18n.default_locale
  end

  def set_header_background
    @bgImg = "/fondos/#{rand(1..16)}.jpg"
  end


  protected

  # Limita la aplicacion a un usuario y contrasenia general
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == CONFIG.username.to_s && password == CONFIG.password.to_s
    end
  end

  # Atributos adicionales para el registro y autenticacion
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :nombre, :apellido, :institucion])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :email, :password, :remember_me])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :nombre, :apellido, :institucion])
  end

  def tiene_permiso?(nombre_rol, con_hijos=false)
    render 'shared/sin_permiso' and return unless usuario_signed_in? #con esto aseguramos que el usuario ya inicio sesión
    roles_usuario = current_usuario.usuario_roles.map(&:rol)
    #Si se es superusuario o algun otro tipo de root, entra a ALL
    return if roles_usuario.map(&:depth).any?{|d| d < 1}
    rol = Rol.find_by_nombre_rol(nombre_rol)
    #Si solicito vástagos, entonces basta con ser hijo del mínimo requerido:
    return if con_hijos && roles_usuario.map(&:path_ids).flatten.include?(rol.id)
    #Si no requiero vastagos revisa si el nombre_rol pertenece al linaje (intersección del subtree_ids del usuario y del rol)
    render 'shared/sin_permiso' unless rol.present? && (roles_usuario.map(&:subtree_ids).flatten & rol.path_ids).any?
  end

  def es_propietario?(obj)
    return false unless usuario_signed_in?
    usuario_id = obj.usuario_id
    current_usuario.id == usuario_id
  end

end
