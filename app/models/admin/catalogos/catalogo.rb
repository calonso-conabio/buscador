class Admin::Catalogo < Catalogo

  attr_accessor :ajax, :especie_id, :catalogo_id, :nombre_cientifico

  has_many :especies_catalogo, class_name: Admin::EspecieCatalogo, foreign_key: attribute_alias(:id), inverse_of: :catalogo
  has_many :especies, -> { order(:nombre_cientifico) }, through: :especies_catalogo, source: :especie

  before_save :verifica_niveles

  scope :select_index, -> { select(:id, :descripcion, :nivel1, :nivel2, :nivel3, :nivel4, :nivel5).select("CONCAT(LPAD(#{attribute_alias(:nivel1)},2,'*'),LPAD(#{attribute_alias(:nivel2)},2,'*'),LPAD(#{attribute_alias(:nivel3)},2,'*'),LPAD(#{attribute_alias(:nivel4)},2,'*'),LPAD(#{attribute_alias(:nivel5)},2,'*')) AS niveles, COUNT(#{Admin::EspecieCatalogo.table_name}.#{Admin::EspecieCatalogo.attribute_alias(:especie_id)}) AS totales") }
  scope :usos, -> { where(nivel1: 11) }

  # Para hacer el query con o sin filtros
  def query_index
    query = Admin::Catalogo.select_index.left_joins(:especies_catalogo).group("#{Admin::Catalogo.table_name}.#{Admin::Catalogo.attribute_alias(:id)}").order("niveles ASC, #{Admin::Catalogo.attribute_alias(:descripcion)} ASC")

    query = query.where(nivel1: nivel1) if nivel1.present?

    if especie_id.present?
      begin
        self.nombre_cientifico = Especie.find(especie_id).nombre_cientifico
      end

      query = query.where("#{Admin::EspecieCatalogo.table_name}.#{Admin::EspecieCatalogo.attribute_alias(:especie_id)}=?", especie_id)
    end

    query
  end

  def dame_nivel1
    Admin::Catalogo.where(nivel2: 0, nivel3: 0, nivel4: 0, nivel5: 0).where("#{Catalogo.attribute_alias(:nivel1)} > ?", 0).order(:descripcion).map{ |c| [c.descripcion, c.nivel1] }
  end

  def dame_nivel2
    return [] unless (nivel2.present? || ajax.present?)
    Admin::Catalogo.where(nivel1: nivel1, nivel3: 0, nivel4: 0, nivel5: 0).where("#{Catalogo.attribute_alias(:nivel2)} > ?", 0).order(:descripcion).map{ |c| [c.descripcion, c.nivel2] }
  end

  def dame_nivel3
    return [] unless (nivel3.present? || ajax.present?)
    Admin::Catalogo.where(nivel1: nivel1, nivel2: nivel2, nivel4: 0, nivel5: 0).where("#{Catalogo.attribute_alias(:nivel3)} > ?", 0).order(:descripcion).map{ |c| [c.descripcion, c.nivel3] }
  end

  def dame_nivel4
    return [] unless (nivel4.present? || ajax.present?)
    Admin::Catalogo.where(nivel1: nivel1, nivel2: nivel2, nivel3: nivel3, nivel5: 0).where("#{Catalogo.attribute_alias(:nivel4)} > ?", 0).order(:descripcion).map{ |c| [c.descripcion, c.nivel4] }
  end

  def dame_nivel5
    return [] unless (nivel5.present? || ajax.present?)
    Admin::Catalogo.where(nivel1: nivel1, nivel2: nivel2, nivel3: nivel3, nivel4: nivel4).where("#{Catalogo.attribute_alias(:nivel5)} > ?", 0).order(:descripcion).map{ |c| [c.descripcion, c.nivel5] }
  end

  accepts_nested_attributes_for :especies_catalogo, reject_if: :all_blank, allow_destroy: true


  private

  def verifica_niveles
    self.nivel1 = 0 unless nivel1.present?
    self.nivel2 = 0 unless nivel2.present?
    self.nivel3 = 0 unless nivel3.present?
    self.nivel4 = 0 unless nivel4.present?
    self.nivel5 = 0 unless nivel5.present?
  end

end
