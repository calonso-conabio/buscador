class EspecieCatalogoRegionBibliografia < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.RelNombreCatalogoRegionBiblio"
  self.primary_keys = :IdCatNombre, :IdNombre, :IdRegion, :IdBibliografia

  alias_attribute :especie_id, :IdNombre
  alias_attribute :catalogo_id, :IdCatNombre
  alias_attribute :region_id, :IdRegion
  alias_attribute :bibliografia_id, :IdBibliografia
  alias_attribute :tipo_distribucion_id, :IdTipoDistribucion
  alias_attribute :observaciones, :Observaciones

  belongs_to :especie, foreign_key: attribute_alias(:especie_id)
  belongs_to :catalogo, foreign_key: attribute_alias(:catalogo_id)
  belongs_to :region, foreign_key: attribute_alias(:region_id)
  belongs_to :bibliografia, foreign_key: attribute_alias(:bibliografia_id)

end
