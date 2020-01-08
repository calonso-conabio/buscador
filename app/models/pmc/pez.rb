class Pmc::Pez < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.pez}.peces"
  self.primary_key = 'especie_id'

  has_many :peces_criterios, :class_name => 'Pmc::PezCriterio', :foreign_key => :especie_id, dependent: :destroy, inverse_of: :pez
  has_many :criterios, :through => :peces_criterios, :source => :criterio
  has_many :criterio_propiedades, :through => :criterios, :source => :propiedad

  has_many :peces_propiedades, :class_name => 'Pmc::PezPropiedad', :foreign_key => :especie_id, dependent: :destroy, inverse_of: :pez
  has_many :propiedades, :through => :peces_propiedades, :source => :propiedad

  belongs_to :especie
  has_one :adicional, :through => :especie, :source => :adicional

  scope :select_joins_peces, -> { select([:nombre_comun_principal, :valor_total, :valor_zonas, :imagen, :con_estrella]).
      select("peces.especie_id, #{Especie.table_name}.#{Especie.attribute_alias(:nombre_cientifico)} AS nombre_cientifico, #{Especie.table_name}.#{Especie.attribute_alias(:ancestry_ascendente_directo)} AS ancestry_ascendente_directo") }

  scope :filtros_peces, -> { select_joins_peces.distinct.left_joins(:criterios, :peces_propiedades, :adicional).
      order(con_estrella: :desc, valor_total: :asc, tipo_imagen: :asc).order("#{Especie.table_name}.#{Especie.attribute_alias(:nombre_cientifico)} ASC") }

  scope :nombres_peces, -> { select([:especie_id, :nombre_cientifico, :nombres_comunes])}
  scope :nombres_cientificos_peces, -> { select(:especie_id).select("nombre_cientifico as label")}
  scope :nombres_comunes_peces, -> { select(:especie_id).select("nombres_comunes as label")}

  attr_accessor :guardar_manual, :anio, :valor_por_zona, :nombre, :importada, :nacional_importada, :en_riesgo, :veda_perm_dep

  validates_presence_of :especie_id
  after_save :actualiza_pez, unless: :guardar_manual
  after_save :guarda_valor_zonas_y_total, unless: :guardar_manual

  accepts_nested_attributes_for :peces_criterios, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :peces_propiedades, reject_if: :all_blank, allow_destroy: true

  GRUPOS_PECES_MARISCOS = %w(Actinopterygii Chondrichthyes Crustacea Mollusca Echinodermata)

  # REVISADO: Corre los metodos necesarios para actualizar el pez
  def actualiza_pez
    guarda_nom_iucn
    asigna_imagen
    guarda_redis
    asigna_valor_zonas_y_total
  end

  # REVISADO: Guarda el redis del pez aprovechando el metodo empaquetado de especie
  def guarda_redis
    especie.guarda_redis(loader: 'peces', foto_principal: imagen)
  end

  # REVISADO: Actualiza todos los servicios
  def self.actualiza_todo
    all.each do |p|
      p.guardar_manual = true
      p.actualiza_pez
      p.save if p.changed?
    end
  end

  # REVISADO: Asigna los valores promedio por zona, de acuerdo a cada estado
  def guarda_valor_zonas_y_total
    asigna_valor_zonas_y_total
    self.guardar_manual = true
    save if valid?
  end

  # REVISADO: Asigna los valores promedio por zona, de acuerdo a todos los criterios
  def asigna_valor_zonas_y_total
    asigna_anio
    valores_por_zona

    criterio_propiedades.select('propiedades.*, valor').cnp.where('anio=?', anio).each do |propiedad|
      zona_num = propiedad.parent.nombre_zona_a_numero  # Para obtener la posicion de la zona

      if propiedad.nombre_propiedad == 'No se distribuye' && !importada  # Quitamos la zona
        self.valor_por_zona[zona_num] = 'n'
      elsif propiedad.nombre_propiedad == 'Estatus no definido' && !importada && !nacional_importada && !en_riesgo && !veda_perm_dep  # La zona se muestra en gris
        self.valor_por_zona[zona_num] = 's'  # Por si se arrepienten
      else
        self.valor_por_zona[zona_num] = valor_por_zona[zona_num] + propiedad.valor
      end
    end

    self.valor_zonas = valor_zona_a_color.join('')
    self.valor_total = color_zona_a_valor.inject(:+)
  end

  # REVISADO: Actualiza todas las zonas y valores totales de todos los peces
  def self.actualiza_todo_valor_zonas_y_total
    all.each do |p|
      p.guardar_manual = true
      p.guarda_valor_zonas_y_total
    end
  end

  # REVISADO: Asigna los valores de la nom de acuerdo a catalogos
  def guarda_nom_iucn
    asigna_anio
    criterio_id = 158

    # Para actualizar o crear el valor de la nom
    if nom = especie.catalogos.nom.first
      if prop = Pmc::Propiedad.where(nombre_propiedad: nom.descripcion).first
        if crit = prop.criterios.where('anio=?', 2012).first
          criterio_id = crit.id
        end
      end
    end

    if crit = criterios.where('anio=?', 2012).nom.first
      pez_crit = peces_criterios.where(criterio_id: crit.id).first
      pez_crit.criterio_id = criterio_id
    else
      pez_crit = peces_criterios.new
      pez_crit.criterio_id = criterio_id # No aplica
    end

    pez_crit.save if pez_crit.changed?

    # Para actualizar o crear el valor de iucn
    criterio_id = 159

    # Para buscar en catalogos
    if iucn = especie.catalogos.iucn.first
      if prop = Pmc::Propiedad.where(nombre_propiedad: iucn.descripcion).first
        if crit = prop.criterios.where('anio=?', 2012).first
          criterio_id = crit.id
        end
      end
    else  # Para el servicio de IUCN
      iucn = IUCNService.new
      if resp = iucn.dameRiesgo(nombre: especie.nombre_cientifico.strip, id: especie_id)
        if prop = Pmc::Propiedad.where(nombre_propiedad: resp).first
          if crit = prop.criterios.where('anio=?', 2012).first
            criterio_id = crit.id
          end
        end
      end
    end

    if crit = criterios.where('anio=?', 2012).iucn.first
      pez_crit = peces_criterios.where(criterio_id: crit.id).first
      pez_crit.criterio_id = criterio_id
    else
      pez_crit = peces_criterios.new
      pez_crit.criterio_id = criterio_id # No aplica
    end

    pez_crit.save if pez_crit.changed?
  end

  # REVISADO: Actualiza las categorias de riesgo de todos los peces
  def self.actualiza_todo_nom_iucn
    all.each do |p|
      p.guardar_manual = true
      p.guarda_nom_iucn
    end
  end

  # REVISADO: Guarda la imagen asociada del pez
  def guarda_imagen
    asigna_imagen
    save if changed?
  end

  # REVISADO: Asigna la ilustracion, foto o ilustracion, asi como el tipo de foto
  def asigna_imagen
    # Trata de asignar la ilustracion
    bdi = BDIService.new
    res = bdi.dameFotos(taxon: especie, campo: 528, autor: 'Sergio de la Rosa Martínez', autor_campo: 80, ilustraciones: true)

    if res[:estatus]
      if res[:fotos].any?
        self.imagen = res[:fotos].first.medium_url
        self.tipo_imagen = 1
        return
      end
    end

    # Trata de asignar la foto principal
    if a = adicional
      foto = a.foto_principal

      if foto.present?
        self.imagen = foto
        self.tipo_imagen = 2
        return
      end
    end

    # Asigna el grupo iconico de la especie
    especie.ancestors.reverse.map(&:nombre_cientifico).each do |nombre|
      if Busqueda::GRUPOS_ANIMALES.include?(nombre.strip)
        self.imagen = "#{nombre.estandariza}-ev-icon"
        self.tipo_imagen = 3
        return
      end
    end

    # Asignar la silueta, el ultimo caso, ya que es una silueta general
    self.imagen = '/assets/app/peces/silueta.png'
    self.tipo_imagen = 4
  end

  # REVISADO: Actualiza la imagen principal de todos los peces
  def self.actualiza_todo_imagen
    all.each do |p|
      p.guardar_manual = true
      p.guarda_imagen
    end
  end

  # REVISADO: Pone el pez con el estatus valido
  def actualiza_pez_valido
    estatus = especie.especies_estatus

    if estatus.length == 1
      esp_id = Especie.find(estatus.first.especie_id2).id
      peces_criterios.update_all(especie_id: esp_id)
      peces_propiedades.update_all(especie_id: esp_id)
      self.especie_id = esp_id
      save
    end
  end

  # REVISADO: Corre el proceso para todos los peces
  def self.actualiza_todos_validos
    all.each do |p|
      if t = p.especie
        next if t.estatus == 2
        p.guardar_manual = true
        p.actualiza_pez_valido
      end
    end
  end


  private

  # REVISADO: Asocia el valor por zona a un color correspondiente
  def valor_zona_a_color
    valor_por_zona.each_with_index do |zona, i|
      next unless zona.class == Integer # Por si ya tiene asignada una letra
      next if i == 6  # Para dejar el valor de nacional o importado

      case zona
      when -5..4
        self.valor_por_zona[i] = 'v'
      when 5..19
        self.valor_por_zona[i] = 'a'
      when 20..200
        self.valor_por_zona[i] = 'r'
      end
    end
  end

  # REVISADO: Este valor es solo de referencia para el valor total
  def color_zona_a_valor
    zonas = []

    valor_zonas.split('').each do |zona|
      case zona
      when 'v'
        zonas << -100
      when 'a'
        zonas << 10
      when 'r'
        zonas << 100
      when 'n', 's'
        zonas << 0
      end
    end

    zonas
  end

  # REVISADO: Para sacar solo el año en cuestion
  def asigna_anio
    self.anio = anio || CONFIG.peces.anio || 2012
  end

  # REVISADO: El valor de los criterios sin la CNP
  def valores_por_zona
    asigna_anio
    valor = 0

    propiedades = criterio_propiedades.select('valor').where('anio=?', anio)
    valor+= propiedades.tipo_capturas.map(&:valor).inject(:+).to_i

    # Para la veda permanente o deportiva
    veda = propiedades.tipo_vedas.map(&:valor).inject(:+).to_i
    valor+= veda
    self.veda_perm_dep = true if veda >= 20

    # Para la nom
    nom = propiedades.nom.map(&:valor).inject(:+).to_i
    valor+= nom
    self.en_riesgo = true if nom >= 20

    # Para la iucn
    iucn = propiedades.iucn.map(&:valor).inject(:+).to_i
    valor+= iucn
    self.en_riesgo = true if iucn >= 20

    # Para la procedencia, si es un caso especial en caso de ser importado
    procedencia_texto = criterio_propiedades.procedencias.first.try(:nombre_propiedad)
    procedencia = propiedades.procedencias.map(&:valor).inject(:+).to_i
    valor+= procedencia

    self.importada = true if procedencia >= 20 && procedencia_texto == 'Importado (huella ecológica alta)'
    self.nacional_importada = true if procedencia >= 20 && procedencia_texto == 'Nacional e Importado (huella ecológica alta)'

    # Para asignar el campo con_estrella que se asocia a las pesquerias sustentables
    pesquerias = propiedades.pesquerias.map(&:valor).inject(:+).to_i

    if pesquerias != 0
      self.con_estrella = 1
    else
      self.con_estrella = 0
    end

    self.valor_por_zona = Array.new(6, valor)

    # Quiere decir que es importado
    if importada
      self.valor_por_zona << 0
    else
      self.valor_por_zona << 1
    end
  end

end