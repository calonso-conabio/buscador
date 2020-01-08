class Fichas::Amenazadirecta < Ficha

  self.table_name = "#{CONFIG.bases.fichasespecies}.amenazadirecta"
  self.primary_key = 'amenazaId'

  has_many :relDemografiaAmenazas, class_name: 'Fichas::Reldemografiaamenazas'

end