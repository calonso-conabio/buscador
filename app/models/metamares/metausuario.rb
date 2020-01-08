class Metausuario < Usuario

  has_one :directorio, :foreign_key => :usuario_id, :class_name=> 'Metamares::Directorio'

  after_create :añade_directorio, :añade_rol

  def dame_usuarios
    usuarios = Metausuario.left_joins(:roles).where("nombre_rol LIKE 'AdminInfoceanos%'")
    usuarios.map { |u| ["#{u.apellido} #{u.nombre}", u.id]}
  end

  def añade_directorio
    Metamares::Directorio.new(usuario_id: self.reload.id).save
  end

  def añade_rol
    self.reload.usuario_roles.new({"rol_id"=>"22"}).save
  end
end