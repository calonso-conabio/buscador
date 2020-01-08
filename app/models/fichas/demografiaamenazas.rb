class Fichas::Demografiaamenazas < Ficha

	self.table_name = "#{CONFIG.bases.fichasespecies}.demografiaamenazas"
	self.primary_keys = :demografiaAmenazasId,  :especieId

	belongs_to :interaccion, :class_name => 'Fichas::Interaccion', :foreign_key => 'interaccionId'
	belongs_to :taxon, :class_name => 'Fichas::Taxon', :foreign_key => 'especieId'

	has_many :relDemografiasAmenazas, class_name: 'Fichas::Reldemografiaamenazas', :foreign_key => 'demografiaAmenazasId'
	has_many :amenazaDirecta, class_name: 'Fichas::Amenazadirecta', through: :relDemografiasAmenazas

	accepts_nested_attributes_for :interaccion, allow_destroy: true
	accepts_nested_attributes_for :amenazaDirecta, allow_destroy: true

end
