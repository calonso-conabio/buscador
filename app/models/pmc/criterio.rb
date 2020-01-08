class Pmc::Criterio < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.pez}.criterios"

  has_many :peces_criterios, :class_name => 'Pmc::PezCriterio', :foreign_key => :criterio_id
  has_many :peces, :through => :peces_criterios, :source => :pez

  belongs_to :propiedad, :class_name => 'Pmc::Propiedad'

  scope :select_propiedades, -> { select('criterios.id, nombre_propiedad') }
  scope :select_join_propiedades, -> { select_propiedades.left_joins(:propiedad) }

  scope :tipo_capturas, -> { select_join_propiedades.where("ancestry=?", Pmc::Propiedad::TIPO_CAPTURA_ID) }
  scope :tipo_vedas, -> { select_join_propiedades.where("ancestry=?", Pmc::Propiedad::TIPO_DE_VEDA_ID) }
  scope :procedencias, -> { select_join_propiedades.where("ancestry=?", Pmc::Propiedad::PROCEDENCIA_ID) }
  scope :nom, -> { select_join_propiedades.where("ancestry=?", Pmc::Propiedad::NOM_ID) }
  scope :iucn, -> { select_join_propiedades.where("ancestry=?", Pmc::Propiedad::IUCN_ID) }
  scope :cnp, -> { select_join_propiedades.where("ancestry REGEXP '323/31[123456]$'").where("tipo_propiedad != 'estado'") }
  scope :iucn_solo_riesgo, -> { iucn.where("propiedades.id IN (400,401,403,404,402)") } #Hardcodear está MAL, hay que evitarlo @calonsot#

  validates_presence_of :valor

  CON_ADVERTENCIA = ['Temporal fija', 'Temporal variable', 'Nacional e Importado'].freeze

  def self.catalogo(prop = nil)

    if prop.present?
      resp = []

      prop.siblings.map do |p|
        next unless p.criterios.present?

        if prop.descripcion.present?
          resp << ["#{p.nombre_propiedad} - #{p.descripcion}", p.criterios.first.id]
        else
          resp << [p.nombre_propiedad, p.criterios.first.id]
        end
      end

      resp

    else
      resp = Rails.cache.fetch('criterios_catalogo', expires_in: eval(CONFIG.cache.peces.catalogos)) do
        grouped_options = {}

        Pmc::Criterio.select(:id, :propiedad_id).group(:propiedad_id).each do |c|
          prop = c.propiedad
          next if prop.existe_propiedad?([Pmc::Propiedad::NOM_ID, Pmc::Propiedad::IUCN_ID])
          llave_unica = prop.ancestors.map(&:nombre_propiedad).join('/')

          grouped_options[llave_unica] = [] unless grouped_options.key?(llave_unica)

          if prop.descripcion.present?
            grouped_options[llave_unica] << ["#{prop.nombre_propiedad} - #{prop.descripcion}", c.id]
          else
            grouped_options[llave_unica] << [prop.nombre_propiedad, c.id]
          end
        end

        grouped_options
      end

      resp
    end
  end

  def self.cnp_select
    cnp_options = ['Con potencial de desarrollo', 'Máximo aprovechamiento permisible', 'En deterioro']
    options = []

    cnp_options.each do |c|
      criterios = self.cnp.where('nombre_propiedad=?', c).map(&:id).join(',')
      options << [c, criterios]
    end

    options
  end

  def self.dame_filtros

    filtros = Rails.cache.fetch('filtros_peces', expires_in: eval(CONFIG.cache.peces.filtros)) do
      {
          grupos: Pmc::Propiedad.grupos_conabio,
          zonas: Pmc::Propiedad.zonas,
          tipo_capturas: self.tipo_capturas,
          tipo_vedas: self.tipo_vedas,
          procedencias: self.procedencias,
          pesquerias: Pmc::Pez.filtros_peces.where(con_estrella: 1).distinct,
          cnp: self.cnp_select,
          nom: self.nom,
          iucn: self.iucn_solo_riesgo
      }
    end

    filtros
  end

end