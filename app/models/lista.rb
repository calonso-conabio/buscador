class Lista < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.ev}.listas"

  attr_accessor :taxones, :taxon, :columnas_array
  validates :nombre_lista, :presence => true, :uniqueness => true
  before_update :quita_repetidos

  #validates :formato, :presence => true

  ESTATUS_LISTA = [
      [0, 'No'],
      [1, 'Sí']
  ]

  FORMATOS = [
      [1, '.csv'],
      [2, '.xlsx'],
      [3, '.txt']
  ]

  FORMATOS_DESCARGA = %w(csv xlsx txt)

  # Columnas permitidas a exportar por el usuario
  COLUMNAS_PROVEEDORES = %w(catalogo_id x_naturalista_id x_snib_id x_snib_reino)
  COLUMNAS_GEODATOS = %w(x_naturalista_obs x_snib_registros x_geoportal_mapa)
  COLUMNAS_RIESGO_COMERCIO = %w(x_nom x_iucn x_cites)
  COLUMNAS_CATEGORIAS = CategoriaTaxonomica::CATEGORIAS.map{|cat| "x_#{cat}"}
  COLUMNAS_CATEGORIAS_PRINCIPALES = %w(x_reino x_division x_phylum x_clase x_orden x_familia x_genero x_especie)
  COLUMNAS_FOTOS = %w(x_foto_principal x_naturalista_fotos x_bdi_fotos)
  COLUMNAS_DEFAULT = %w(id nombre_cientifico x_nombre_comun_principal x_nombres_comunes x_categoria_taxonomica
                        x_estatus x_tipo_distribucion
                        cita_nomenclatural nombre_autoridad)
  COLUMNAS_GENERALES = COLUMNAS_DEFAULT + COLUMNAS_RIESGO_COMERCIO + COLUMNAS_CATEGORIAS_PRINCIPALES

  def after_initialize
    self.taxones = []
    self.columnas_array = []
  end

  # Crea el csv con los datos
  def to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << nombres_columnas
      datos # Completa los datos de los taxones por medio del ID

      taxones.each do |taxon|
        datos_taxon = []

        columnas.split(',').each do |col|
          datos_taxon << eval("taxon.#{col}")
        end
        csv << datos_taxon
      end
    end
  end

  # Para crear el excel con los datos
  def to_excel(opts={})
    xlsx = RubyXL::Workbook.new
    sheet = xlsx[0]
    sheet.sheet_name = 'Resultados'
    fila = 1  # Para no sobreescribir la cabecera
    columna = 0
    cols = columnas_array if columnas_array.present?  # Para no sobreescribir el atributo original columnas
    cols = columnas.split(',') if columnas.present?


    # Para la cabecera
    cols.each do |a|
      sheet.add_cell(0,columna,I18n.t("listas_columnas.generales.#{a}", default: I18n.t("listas_columnas.categorias.#{a}", default: a)))
      columna+= 1
    end

    # Elimina las 3 primeras, para que no trate de evaluarlas mas abajo
    cols.slice!(0..2) if opts[:asignar]

    if opts[:es_busqueda]  # Busqueda basica o avanzada
      r = Especie.find_by_sql(opts[:busqueda])
      datos_descarga(r)
    elsif opts[:ubicaciones]  # Descarga taxa de ubicaciones
      r = Especie.where(id: cadena_especies.split(','))
      datos_descarga(r)
    end

    taxones.each do |taxon|
      if opts[:asignar]
        # Viene del controlador validaciones, taxon contiene, estatus, el taxon y mensaje
        if taxon[:estatus]  # Si es un sinónimo
          if taxon[:taxon_valido].present?
            self.taxon = taxon[:taxon_valido]
          else  # La rewspuesta es el taxon que encontro
            self.taxon = taxon[:taxon]
          end

          nombre_cientifico = self.taxon.nombre_cientifico

        else  # Si tiene muchos taxones como coincidencia
          self.taxon = Especie.none

          if taxon[:taxones].present?  # Cuando coincidio varios taxones no pongo nada
            nombre_cientifico = taxon[:taxones].map{|t| t.nombre_cientifico}.join(', ')
          else
            nombre_cientifico = ''
          end
        end

        asigna_datos
        columna = 3  # Asigna la columna desde el 3, puesto que contiene las sig posiciones antes:

        # El nombre original, el (los) que coincidio, y el mensaje
        sheet.add_cell(fila,0,taxon[:nombre_orig])
        sheet.add_cell(fila,1,nombre_cientifico)
        sheet.add_cell(fila,2,taxon[:msg])

      else  # Cuando viene de una descarga normal de resultados, es decir todos los taxones existen
        self.taxon = taxon
        columna = 0
      end

      cols.each do |a|
        begin
          sheet.add_cell(fila,columna,self.taxon.try(a))
        rescue  # Por si existe algun error en la evaluacion de algun campo
          sheet.add_cell(fila,columna,'¡Hubo un error!')
        end
        columna+= 1
      end

      fila+= 1
    end

    # Escribe el excel en cierta ruta
    fecha = Time.now.strftime("%Y-%m-%d")
    ruta_dir = Rails.root.join('public','descargas_resultados', fecha)
    nombre_archivo = Time.now.strftime("%Y-%m-%d_%H-%M-%S-%L") + '_taxa_EncicloVida.xlsx'
    FileUtils.mkpath(ruta_dir, :mode => 0755) unless File.exists?(ruta_dir)
    ruta_excel = ruta_dir.join(nombre_archivo)
    xlsx.write(ruta_excel)

    if File.exists? ruta_excel
      excel_url = "#{CONFIG.site_url}descargas_resultados/#{fecha}/#{nombre_archivo}"

      if opts[:correo].present?
        EnviaCorreo.descargar_taxa(excel_url, opts[:correo], opts[:original_url]).deliver
      end

      {estatus: true, excel_url: excel_url}
    else
      {estatus: true, msg: 'No pudo guardar el archivo'}
    end

  end

  # Para asignar los datos de una lista de ids de especies, hacia un excel o csv, el recurso puede ser un string o un objeto
  def datos(opc={})
    return [] unless cadena_especies.present?

    # Por default muestra todos
    Especie.caso_rango_valores('especies.id',cadena_especies).order('nombre_cientifico ASC').limit(opc[:limit] ||= 300000).each do |taxon|
      self.taxon = taxon
      asigna_datos
      self.taxones << taxon
    end
  end

  # Para asignar los datos de una consulta de resultados, hacia un excel o csv, el recurso puede ser un string o un objeto
  def datos_descarga(taxones)
    return unless taxones.any?
    self.taxones = []

    taxones.each do |taxon|
      self.taxon = taxon
      asigna_datos
      self.taxones << taxon
    end
  end

  # Metodoq ue comparten las listas y para exportar en excel
  def asigna_datos
    return unless taxon.present?

    if columnas.present?
      cols = columnas.split(',')
    elsif columnas_array.present?
      cols = columnas_array
    end

    cols.each do |col|

      case col
      when 'x_snib_id'
        if proveedor = taxon.proveedor
          self.taxon.x_snib_id = proveedor.snib_id
        end
      when 'x_snib_reino'
        if proveedor = taxon.proveedor
          self.taxon.x_snib_reino = proveedor.snib_reino
        end
      when 'x_naturalista_id'
        if proveedor = taxon.proveedor
          self.taxon.x_naturalista_id = proveedor.naturalista_id
        end
      when 'x_foto_principal'
        if adicional = taxon.adicional
          self.taxon.x_foto_principal = adicional.foto_principal
        end
      when 'x_nombre_comun_principal'
        if adicional = taxon.adicional
          self.taxon.x_nombre_comun_principal = adicional.nombre_comun_principal
        end
      when 'x_categoria_taxonomica'
        self.taxon.x_categoria_taxonomica = taxon.try(:nombre_categoria_taxonomica) || taxon.categoria_taxonomica.nombre_categoria_taxonomica
      when 'x_estatus'
        self.taxon.x_estatus = Especie::ESTATUS_SIGNIFICADO[taxon.estatus]
      when 'x_nombres_comunes'
        nombres_comunes = taxon.nombres_comunes.order(:nombre_comun).map{|nom| "#{nom.nombre_comun.capitalize} (#{nom.lengua})"}.uniq
        next unless nombres_comunes.any?
        self.taxon.x_nombres_comunes = nombres_comunes.join(',')
      when 'x_tipo_distribucion'
        tipos_distribuciones = taxon.tipos_distribuciones.map(&:descripcion).uniq
        next unless tipos_distribuciones.any?
        self.taxon.x_tipo_distribucion = tipos_distribuciones.join(',')
      when 'x_nom'
        nom = taxon.catalogos.nom.distinct
        next unless nom.any?
        self.taxon.x_nom = nom[0].descripcion
      when 'x_iucn'
        iucn = taxon.catalogos.iucn.distinct
        next unless iucn.any?
        self.taxon.x_iucn = iucn[0].descripcion
      when 'x_cites'
        cites = taxon.catalogos.cites.distinct
        next unless cites.any?
        self.taxon.x_cites = cites[0].descripcion
      when 'x_naturalista_fotos'
        next unless adicional = taxon.adicional
        if proveedor = taxon.proveedor
          self.taxon.x_naturalista_fotos = "#{CONFIG.site_url}especies/#{taxon.id}/fotos-naturalista" if proveedor.naturalista_id.present? && adicional.foto_principal.present?
        end
      when 'x_bdi_fotos'
        next unless adicional = taxon.adicional
        self.taxon.x_bdi_fotos = "#{CONFIG.site_url}especies/#{taxon.id}/fotos-bdi" if adicional.foto_principal.present?
      else
        next
      end  # End switch
    end  # End each cols

    # Para agregar todas las categorias taxonomicas que pidio, primero se intersectan
    cats = COLUMNAS_CATEGORIAS & cols

    if cats.any?
      return if taxon.is_root?  # No hay categorias que completar
      ids = taxon.path_ids

      Especie.select(:nombre, "#{CategoriaTaxonomica.attribute_alias(:nombre_categoria_taxonomica)} AS nombre_categoria_taxonomica").left_joins(:categoria_taxonomica).where(id: ids).each do |ancestro|
        categoria = 'x_' << ancestro.nombre_categoria_taxonomica.estandariza
        next unless COLUMNAS_CATEGORIAS.include?(categoria)
        eval("self.taxon.#{categoria} = ancestro.nombre")  # Asigna el nombre del ancestro si es que coincidio con la categoria
      end
    end
  end

  def nombres_columnas(web = false)
    cabecera = []
    columnas.split(',').each do |col|
      cabecera << I18n.t("listas_columnas.generales.#{col}", default: I18n.t("listas_columnas.categorias.#{col}"))
    end
    web ? cabecera.join(',') : cabecera
  end

  private

  def quita_repetidos
    self.cadena_especies = cadena_especies.split(',').compact.uniq.join(',') if cadena_especies.present?
  end

end
