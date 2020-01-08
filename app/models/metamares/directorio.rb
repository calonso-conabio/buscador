class Metamares::Directorio < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.directorio"

  validates_uniqueness_of :usuario_id

end