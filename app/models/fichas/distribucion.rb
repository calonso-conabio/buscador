class Fichas::Distribucion < Ficha
  self.table_name = "#{CONFIG.bases.fichasespecies}.distribucion"
  self.primary_key = 'distribucionId'

  belongs_to :taxon, :class_name => 'Fichas::Taxon', :foreign_key => 'especieId', primary_key: 'especieId'
  has_many :relDistribucionesEstados, class_name: 'Fichas::Reldistribucionestado'
  has_many :relDistribucionesMunicipios, class_name: 'Fichas::Reldistribucionmunicipio'
  has_many :relDistribucionesPaises, class_name: 'Fichas::Reldistribucionpais', :foreign_key => 'distribucionId', inverse_of: :distribucion

  accepts_nested_attributes_for :relDistribucionesPaises, allow_destroy: true

end