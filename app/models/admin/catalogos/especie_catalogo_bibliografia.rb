class Admin::EspecieCatalogoBibliografia < EspecieCatalogoBibliografia

  has_many :bibliografias, class_name: 'Admin::Bibliografia', primary_key: attribute_alias(:bibliografia_id), foreign_key: attribute_alias(:bibliografia_id)

end