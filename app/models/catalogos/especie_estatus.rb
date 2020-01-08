class EspecieEstatus < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.Nombre_Relacion"
  self.primary_keys= :IdNombre, :IdNombreRel, :IdTipoRelacion

  # Los alias con las tablas de catalogos
  alias_attribute :especie_id1, :IdNombre
  alias_attribute :especie_id2, :IdNombreRel
  alias_attribute :estatus_id, :IdTipoRelacion
  alias_attribute :observaciones, :Observaciones

  belongs_to :especie, :foreign_key => attribute_alias(:especie_id1)
  belongs_to :especie, :foreign_key => attribute_alias(:especie_id2)
  belongs_to :estatus, :foreign_key => attribute_alias(:estatus_id)
  has_many :bibliografias, class_name: 'EspecieEstatusBibliografia', :foreign_key => attribute_alias(:especie_id1)

  scope :sinonimos, -> { where(estatus_id: [1,2]) }
  scope :homonimos, -> { where(estatus_id: 8) }

end
