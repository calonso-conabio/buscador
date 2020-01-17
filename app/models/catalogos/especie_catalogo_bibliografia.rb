class EspecieCatalogoBibliografia < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.RelNombreCatalogoBiblio"
  self.primary_keys = :IdCatNombre, :IdNombre, :IdBibliografia

  # Los alias con las tablas de catalogos
  alias_attribute :especie_id, :IdNombre
  alias_attribute :catalogo_id, :IdCatNombre
  alias_attribute :bibliografia_id, :IdBibliografia

  belongs_to :especie, :foreign_key => attribute_alias(:especie_id)
  belongs_to :catalogo, :foreign_key => attribute_alias(:catalogo_id)
  belongs_to :bibliografia, :foreign_key => attribute_alias(:bibliografia_id)

end