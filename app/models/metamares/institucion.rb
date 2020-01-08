class Metamares::Institucion < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.instituciones"

  #belongs_to :ubicacion, class_name: 'Metamares::Ubicacion', inverse_of: :institucion, foreign_key: :ubicacion_id
  has_many :proyectos, class_name: 'Metamares::Proyecto', inverse_of: :institucion

  before_save :actualiza_slug
  validates_presence_of :nombre_institucion

  def busca_institucion
    return [] unless nombre_institucion.present?
    Metamares::Institucion.where('slug REGEXP ?', nombre_institucion.estandariza).limit(15).order(:nombre_institucion)
  end


  private

  def actualiza_slug
    self.slug = nombre_institucion.estandariza
  end

end