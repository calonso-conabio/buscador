class Admin::Catalogo < Catalogo

  has_many :especies_catalogo, class_name: Admin::EspecieCatalogo, foreign_key: attribute_alias(:id), inverse_of: :catalogo
  has_many :especies, -> { order(:nombre_cientifico) }, through: :especies_catalogo, source: :especie

  scope :usos_count, -> { select(:id, :descripcion).select('COUNT(*) AS totales').group(:id, :descripcion) }
  scope :usos, -> { usos_count.joins(:especies_catalogo).where(nivel1: 11).order(:descripcion) }

  accepts_nested_attributes_for :especies_catalogo, reject_if: :all_blank, allow_destroy: true

end
