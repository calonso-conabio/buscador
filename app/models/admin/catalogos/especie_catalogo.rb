class Admin::EspecieCatalogo < EspecieCatalogo

  has_many :bibliografias, class_name: Admin::EspecieCatalogoBibliografia, primary_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id)], foreign_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id)]
  has_many :regiones, class_name: Admin::EspecieCatalogoRegion, primary_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id)], foreign_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id)]

  attr_accessor :nombre_cientifico
  accepts_nested_attributes_for :bibliografias, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :regiones, reject_if: :all_blank, allow_destroy: true

end
