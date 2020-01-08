class Fichas::Legislacion < Ficha

	self.table_name = "#{CONFIG.bases.fichasespecies}.legislacion"
	self.primary_keys = :legislacionId,  :especieId

	belongs_to :taxon, :class_name => 'Fichas::Taxon', :foreign_key => 'especieId'

	ESTATUS_LEGAL_PROTECCION = [:Amenazadas, :SujetasProteccionEspecial, :PreocupacionMenor]
	# Legislaciones existentes
	TIPOS_LEGISLACIONES = ["NOM-059-SEMARNAT-2001", "NOM-059-SEMARNAT", "UICN", "CITES"]

	attr_accessor :SEMARNAT_2001

	def existe_legislacion(lista, num)
		lista.each do |a|
			if a.nombreLegislacion == Fichas::Legislacion::TIPOS_LEGISLACIONES[num]
				return a
			end
		end
	end


end
