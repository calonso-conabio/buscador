class Metamares::Keyword < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.keywords"

  belongs_to :proyecto, class_name: 'Metamares::Proyecto'

  before_save :actualiza_slug
  validates_presence_of :nombre_keyword

  def busca_keyword
    return [] unless nombre_keyword.present?
    Metamares::Keyword.select('nombre_keyword, COUNT(*) AS totales').where('slug REGEXP ?', nombre_keyword.estandariza).
        limit(15).order('totales DESC').group(:nombre_keyword)
  end


  private

  def actualiza_slug
    self.slug = nombre_keyword.estandariza
  end

end