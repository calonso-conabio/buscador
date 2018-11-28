class Metausuario < Usuario

  has_one :directorio, :foreign_key => :usuario_id, :class_name=> 'Metamares::Directorio'

  after_create :añade_directorio

  def dame_usuarios
    usuarios = Metausuario.left_joins(:roles).where("nombre_rol LIKE 'AdminMetamares%'")
    usuarios.map { |u| ["#{u.apellido} #{u.nombre}", u.id]}
  end

  def añade_directorio
    directorio.new.save
  end

end