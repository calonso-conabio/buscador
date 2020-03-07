class EspecieCatalogo < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.RelNombreCatalogo"
  self.primary_keys = :IdCatNombre, :IdNombre

  # Los alias con las tablas de catalogos
  alias_attribute :especie_id, :IdNombre
  alias_attribute :catalogo_id, :IdCatNombre
  alias_attribute :observaciones, :Observaciones

  attr_accessor :catalogo_id_falso
  belongs_to :especie, foreign_key: attribute_alias(:especie_id)
  belongs_to :catalogo, foreign_key: attribute_alias(:catalogo_id)

  has_many :biblios, :class_name => 'EspecieCatalogoBibliografia', :dependent => :destroy, :foreign_key => attribute_alias(:especie_id)

end
