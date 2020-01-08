require 'digest/sha2'

class Usuario < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.ev}.usuarios"

  # Para validar un correo y otros modelos lo puedan utilizar
  nombre_correo_regex  = '[\w\.%\+\-]+'.freeze
  dominio_regex = '(?:[A-Z0-9\-]+\.)+'.freeze
  dominio_tld_regex  = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'.freeze
  CORREO_REGEX       = /\A#{nombre_correo_regex}@#{dominio_regex}#{dominio_tld_regex}\z/i
  CORREO_INVALIDO_MSG = 'no tiene la estructura apropiada.'.freeze

  has_many :usuario_roles, :class_name=> 'UsuarioRol', :foreign_key => :usuario_id
  accepts_nested_attributes_for :usuario_roles, reject_if: :all_blank, allow_destroy: true

  has_many :roles, :through => :usuario_roles, :source => :rol
  has_many :categorias_contenidos, :through => :roles, :source => :categorias_contenidos

  has_many :usuario_especies, :class_name=> 'UsuarioEspecie', :foreign_key => :usuario_id
  has_many :especies, :through => :usuario_especies, :source => :especie

  attr_accessor :login
  validates :nombre, :apellido, presence: true

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :omniauthable, :lockable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :timeoutable,
         :authentication_keys => [:login]

  scope :select_para_joins, -> { select("usuarios.id, usuarios.nombre, usuarios.apellido, usuarios.email, usuarios.institucion, usuarios.observaciones, roles.nombre_rol, #{Especie.table_name}.#{Especie.attribute_alias(:id)} AS id_especie, #{Especie.table_name}.#{Especie.attribute_alias(:nombre_cientifico)} AS nombre_cientifico, categorias_contenido.nombre AS nombre_cc")}
  scope :join_userRolEspeciesCategoriasContenido,-> { select_para_joins.left_joins(:roles, :especies, :categorias_contenidos) }

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where('LOWER(email) = ?', login.downcase).first
    else
      where(conditions).first
    end
  end

  def nombre_completo
    "#{id}. #{nombre} #{apellido}"
  end
end
