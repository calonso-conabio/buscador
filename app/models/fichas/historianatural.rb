class Fichas::Historianatural < Ficha

	self.table_name = "#{CONFIG.bases.fichasespecies}.historianatural"
	self.primary_keys = :historiaNaturalId,  :especieId

	belongs_to :cat_estrategiaTrofica, :class_name => 'Fichas::Cat_Estrategiatrofica', :foreign_key => 'IdEstrategia'
	belongs_to :reproduccionAnimal, :class_name => 'Fichas::Reproduccionanimal', :foreign_key => 'reproduccionAnimalId'
	belongs_to :reproduccionVegetal, :class_name => 'Fichas::Reproduccionvegetal', :foreign_key => 'reproduccionVegetalId'
	belongs_to :taxon, :class_name => 'Fichas::Taxon', :foreign_key => 'especieId'

	has_many :relHistoriasNaturalesPais, class_name: 'Fichas::Relhistorianaturalpais'
	has_many :relHistoriasNaturalesUsos, class_name: 'Fichas::Relhistorianaturalusos', :foreign_key => 'historiaNaturalId'

	has_many :culturaUsos, class_name: 'Fichas::Culturausos', through: :relHistoriasNaturalesUsos

	accepts_nested_attributes_for :culturaUsos, allow_destroy: true
	accepts_nested_attributes_for :reproduccionAnimal, allow_destroy: true
	accepts_nested_attributes_for :reproduccionVegetal, allow_destroy: true

	def get_info_reproduccion
		if self.tipoReproduccion == 'animal'
			return self.reproduccionAnimal
		else
			return self.reproduccionVegetal
		end
	end

end
