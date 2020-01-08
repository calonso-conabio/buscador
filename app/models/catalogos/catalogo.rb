class Catalogo < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.CatalogoNombre"
  self.primary_key = 'IdCatNombre'

  # Los alias con las tablas de catalogos
  alias_attribute :id, :IdCatNombre
  alias_attribute :descripcion, :Descripcion
  alias_attribute :nivel1, :Nivel1
  alias_attribute :nivel2, :Nivel2
  alias_attribute :nivel3, :Nivel3
  alias_attribute :nivel4, :Nivel4
  alias_attribute :nivel5, :Nivel5

  scope :nom, -> { where(nivel1: 4, nivel2: 1).where("#{attribute_alias(:nivel3)} > 0") }
  scope :iucn, -> { where(nivel1: 4, nivel2: 2).where("#{attribute_alias(:nivel3)} > 0").where.not(descripcion: 'Riesgo bajo (LR): Dependiente de conservación (cd)') }
  scope :cites, -> { where(nivel1: 4, nivel2: 3).where("#{attribute_alias(:nivel3)} > 0") }
  scope :prioritarias, -> { where(nivel1: 4, nivel2: 4).where("#{attribute_alias(:nivel3)} > 0") }
  scope :ambientes, -> { where(:nivel1 => 2, :nivel2 => 6).where('nivel3 > 0').where.not(descripcion: AMBIENTE_EQUIV_MARINO) }

  AMBIENTE_EQUIV_MARINO = ['Nerítico', 'Nerítico y oceánico', 'Oceánico']

  # REVISADO: Regresa true or false si el catalogo es de los permitidos a mostrar
  def es_catalogo_permitido?
    (((nivel1 == 4 && (1..4).include?(nivel2)) || (nivel1 == 2 && nivel2 == 6)) && nivel3 > 0) || (nivel1 == 18 && nivel2 > 0)
  end

  # REVISADO: Regresa la categoria superior del nombre del catalogo
  def dame_nombre_catalogo
    if nivel1 == 18
      if cat = Catalogo.where(nivel1: nivel1, nivel2: 0, nivel3: 0).first
        cat.descripcion
      end

    else
      if cat = Catalogo.where(nivel1: nivel1, nivel2:nivel2, nivel3: 0).first
        cat.descripcion
      else
        'No determinado'
      end
    end
  end

  # REVISADO: regresa todos los ambientes
  def self.ambiente_todos
    ambientes
  end

  # REVISADO: Las categorias de conservacion para la busqueda avanzada
  def self.nom_cites_iucn_todos
    nom = self.nom#.map(&:descripcion)
    nom = [nom[3],nom[1],nom[0],nom[2]]  # Orden propuesto por cgalindo
    iucn = self.iucn#.map(&:descripcion)
    iucn = [iucn[4],iucn[3],iucn[2],iucn[1],iucn[0]]  # Orden propuesto por cgalindo
    cites = self.cites#.map(&:descripcion) #Esta ya viene en orden (I,II,III)
    {:nom => nom, :iucn => iucn, :cites => cites}
  end

  # REVISADO: Regresa todas las proritarias
  def self.prioritaria_todas
    prioritarias
  end
end
