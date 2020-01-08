class Fichas::Taxon < Ficha

	self.table_name = "#{CONFIG.bases.fichasespecies}.taxon"
	self.primary_key = 'especieId'

	has_many :caracteristicasEspecies, :class_name => 'Fichas::Caracteristicasespecie', :foreign_key => 'especieId'
	has_many :conservacion, :class_name => 'Fichas::Conservacion', :foreign_key => 'especieId'
	has_many :demografiaAmenazas, :class_name=> 'Fichas::Demografiaamenazas', :foreign_key => 'especieId'
	has_many :distribuciones, :class_name => 'Fichas::Distribucion', :foreign_key => 'especieId', inverse_of: :taxon
  has_many :endemicas, :class_name => 'Fichas::Endemica', :foreign_key => 'especieId'
	has_many :habitats, class_name: 'Fichas::Habitat', :foreign_key => 'especieId'
	has_one :historiaNatural, class_name: 'Fichas::Historianatural', :foreign_key => 'especieId'
	has_many :legislaciones, class_name: 'Fichas::Legislacion', :foreign_key => 'especieId'
	has_many :metadatos, class_name: 'Fichas::Metadatos', :foreign_key => 'especieId'
	has_one :nombreComun, class_name: 'Fichas::Nombrecomun', :foreign_key => 'especieId'
	has_many :productoComercios, class_name: 'Fichas::Productocomercio', :foreign_key => 'especieId'
	has_many :sinonimos , class_name: 'Fichas::Sinonimo', :foreign_key => 'especieId'
	has_many :referenciasBibliograficas, class_name: 'Fichas::Referenciabibliografica', :foreign_key => 'especieId'
	has_many :observacionescaracs,class_name: 'Fichas::Observacionescarac', :foreign_key =>'especieId'

  has_one :scat, class_name: 'Scat', primary_key: :IdCAT, foreign_key: Scat.attribute_alias(:catalogo_id)
  has_one :especie, through: :scat, source: :especie

	accepts_nested_attributes_for :distribuciones, allow_destroy: true
	accepts_nested_attributes_for :habitats, allow_destroy: true
  accepts_nested_attributes_for :demografiaAmenazas, allow_destroy: true
	accepts_nested_attributes_for :historiaNatural, allow_destroy: true
  accepts_nested_attributes_for :conservacion, allow_destroy: true
  accepts_nested_attributes_for :legislaciones, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :endemicas, allow_destroy: true

	# Para sección de especies prioritarias
	ESPECIE_ENLISTADA = [:yes, :no]
	LISTADOS = [:DOF, :CONABIO]
	PRIORIDADS = [:alta, :media, :baja]

  # Devuelve las secciones que tienen información
	def dame_edad_peso_largo
		datos = {}
		datos[:estatus] = false

		if edadinicialmachos.present? || edadfinalmachos.present? || edadinicialhembras.present? || edadfinalhembras.present?
			datos[:edad] = true
			datos[:estatus] = true
		end

		if pesoinicialmachos.present? || pesofinalmachos.present? || pesoinicialhembras.present? || pesofinalhembras.present?
			datos[:peso] = true
			datos[:estatus] = true unless datos[:estatus]
		end

		if largoinicialmachos.present? || largofinalmachos.present? || largoinicialhembras.present? || largofinalhembras.present?
			datos[:largo] = true
			datos[:estatus] = true unless datos[:estatus]
		end

		datos
	end

end

class Numerador

	include Singleton

	def initialize
    @pregunta = 0
    @nivel = 1
    @tipo_r = "A"
	end

  def x_pregunta (nivel = 1, tipo_r = "A")

		if nivel == 1
			@pregunta += 1
		end

    "#{@pregunta}. "
  end

end