class Admin::EspecieCatalogoRegion < EspecieCatalogoRegion

  attr_accessor :reg

  has_many :bibliografias, class_name: 'Admin::EspecieCatalogoRegionBibliografia', primary_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id),attribute_alias(:region_id)], foreign_key: [attribute_alias(:especie_id),attribute_alias(:catalogo_id),attribute_alias(:region_id)]

  accepts_nested_attributes_for :bibliografias, reject_if: :all_blank, allow_destroy: true

end
