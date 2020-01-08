class Metamares::EspecieEstudiada < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.especies_estudiadas"

  belongs_to :proyecto, class_name: 'Metamares::Proyecto'
  belongs_to :especie, class_name: 'Especie'
  has_one :adicional, through: :especie, source: :adicional

end