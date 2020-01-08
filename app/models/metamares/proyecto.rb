class Metamares::Proyecto < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.proyectos"

  belongs_to :info_adicional, class_name: 'Metamares::InfoAdicional', dependent: :destroy
  belongs_to :periodo, class_name: 'Metamares::Periodo', dependent: :destroy
  belongs_to :region, class_name: 'Metamares::RegionM', dependent: :destroy
  belongs_to :dato, class_name: 'Metamares::Dato', dependent: :destroy
  belongs_to :institucion, class_name: 'Metamares::Institucion', inverse_of: :proyectos
  #has_one :ubicacion, through: :institucion, source: :ubicacion
  belongs_to :usuario, class_name: 'Usuario'
  has_many :especies, class_name: 'Metamares::EspecieEstudiada', dependent: :destroy
  has_many :keywords, class_name: 'Metamares::Keyword', dependent: :destroy

  accepts_nested_attributes_for :info_adicional, allow_destroy: true
  accepts_nested_attributes_for :periodo, allow_destroy: true
  accepts_nested_attributes_for :region, allow_destroy: true
  accepts_nested_attributes_for :institucion, reject_if: :all_blank
  #accepts_nested_attributes_for :ubicacion, reject_if: :all_blank
  accepts_nested_attributes_for :dato, allow_destroy: true
  accepts_nested_attributes_for :especies, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :keywords, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :nombre_proyecto, :usuario_id
  attr_accessor :nom_institucion

  TIPO_MONITOREO = %w(especie grupo-especie socio-economico ecosistemas fisico-quimico)
  FINANCIAMIENTOS = [:ACADEMIC_F, :OSC_F, :ACA_F, :GOV_F, :IGO_F, :INT_F, :NGO_F, :Private_F, :Unknown]
  CAMPOS_INVESTIGACION = [:Aquaculture, :Conservation, :Ecology, :Fisheries, :Oceanography, :Other, :Sociology, :Tourism]
  CAMPOS_CIENCIAS = ['Natural Science'.to_sym, 'Social Science'.to_sym]

end