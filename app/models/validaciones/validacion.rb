# Modelo sin tabla, solo para automatizar la validacion de archivos excel
class Validacion

  # El excel que subio, la cabecera del excel, la fila en cuestion del excel y la respuesta de alguna consulta, y el excel de respuesta
  attr_accessor :nombre_cientifico, :archivo_copia, :correo, :excel_url, :nombre_archivo, :sheet, :recurso_validado, :cabecera, :validacion

  FORMATOS_PERMITIDOS = %w(application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
  #FORMATOS_PERMITIDOS = %w(application/vnd.openxmlformats-officedocument.spreadsheetml.sheet text/csv text/plain)

  # Inicializa las variables
  def initialize
    self.recurso_validado = []
    self.validacion = {}
  end

  # Encuentra el mas parecido
  def encuentra_por_nombre
    Rails.logger.debug "Encuentra record por nombre cientifico: #{nombre_cientifico}"
    # Evita que el nombre cientifico este vacio
    if nombre_cientifico.blank?
      self.validacion = {estatus: false, msg: 'El nombre cientifico está vacío'}
      return
    end

    taxones = Especie.solo_publicos.where("LOWER(#{Especie.attribute_alias(:nombre_cientifico)}) = ?", nombre_cientifico.limpia.downcase).order(estatus: :desc)

    if taxones.length == 1  # Caso mas sencillo, coincide al 100 y solo es uno
      Rails.logger.debug "Coincidio busqueda exacta"
      self.validacion = {estatus: true, taxon: taxones.first, msg: 'Búsqueda exacta'}
      return

    elsif taxones.length > 1  # Encontro el mismo nombre cientifico mas de una vez
      Rails.logger.debug "Coincidio mas de uno directo en la base"
      self.validacion = {estatus: false, taxones: taxones, msg: 'Existe más de una búsqueda exacta'}
      return

    else
      Rails.logger.debug "Tratando de encontrar concidencias con la base, separando el nombre"
      # Parte de expresiones regulares a ver si encuentra alguna coincidencia
      nombres = I18n.transliterate(nombre_cientifico.limpia.limpiar.limpia_sql.downcase).split(' ')

      taxones = if nombres.length == 2  # Especie
                  Especie.solo_publicos.where("LOWER(#{Especie.attribute_alias(:nombre_cientifico)}) LIKE '#{nombres[0]} % #{nombres[1]}'")
                elsif nombres.length == 3  # Infraespecie
                  Especie.solo_publicos.where("LOWER(#{Especie.attribute_alias(:nombre_cientifico)}) LIKE '#{nombres[0]}%#{nombres[1]}%#{nombres[2]}'")
                elsif nombres.length == 1 # Genero o superior
                  Especie.solo_publicos.where("LOWER(#{Especie.attribute_alias(:nombre_cientifico)}) LIKE '#{nombres[0]}'")
                end

      if taxones.present? && taxones.length == 1  # Caso mas sencillo
        self.validacion = {estatus: true, taxon: taxones.first, msg: 'Búsqueda similar'}
        return

      elsif taxones.present? && taxones.length > 1  # Mas de una coincidencia
        self.validacion = {estatus: false, taxones: taxones, msg: 'Existe más de una búsqueda similar'}
        return

      else  # Lo buscamos con el fuzzy match y despues con el algoritmo levenshtein
        Rails.logger.debug "Tratando de encontrar concidencias con el fuzzy match"

        if Rails.env.development_mac?
          ids = []
        else
          ids = FUZZY_NOM_CIEN.find(nombre_cientifico.limpia, limit=CONFIG.limit_fuzzy).map{ |t| t.first}
        end

        if ids.present?
          taxones = Especie.solo_publicos.where(id: ids)
          taxones_con_distancia = []

          taxones.each do |taxon|
            # Si la distancia entre palabras es menor a 3 que muestre la sugerencia
            distancia = Levenshtein.distance(nombre_cientifico.limpia.downcase, taxon.nombre_cientifico.limpia.downcase)
            next if distancia > 2  # No cumple con la distancia
            taxones_con_distancia << taxon
          end

          if taxones_con_distancia.empty?
            Rails.logger.debug "Sin coincidencia"
            self.validacion = {estatus: false, msg: 'Sin coincidencias'}
            return
          else
            if taxones_con_distancia.length == 1
              if nombre_cientifico.downcase == taxones_con_distancia.first.nombre_cientifico.limpiar(tipo: 'ssp').downcase  # Era el mismo, solo que tenia ssp. en vez de subsp.
                Rails.logger.debug "-#{nombre_cientifico.limpiar.estandariza}-#{taxones_con_distancia.first.nombre_cientifico.limpiar.estandariza}-"
                self.validacion = {estatus: true, taxon: taxones_con_distancia.first, msg: 'Búsqueda similar'}
              else
                self.validacion = {estatus: true, taxon: taxones_con_distancia.first, msg: 'Búsqueda similar'}
              end

              return
            else
              self.validacion = {estatus: false, taxones: taxones_con_distancia, msg: 'Existe más de una búsqueda similar'}
            end
          end

        else  # No hubo coincidencias con su nombre cientifico
          Rails.logger.debug "Sin coincidencia"
          self.validacion = {estatus: false, msg: 'Sin coincidencias'}
          return
        end
      end

    end  #Fin de las posibles coincidencias
  end

  def dame_sheet
    Rails.logger.debug "Validando el archivo ..."

    xlsx = Roo::Excelx.new(archivo_copia, packed: nil, file_warning: :ignore)
    self.sheet = xlsx.sheet(0)  # toma la primera hoja por default
  end

  def valida_archivo
    dame_sheet
  end

  # Este metodo se manda a llamar cuando el taxon coincidio ==  validacion[:estatus] = true
  def taxon_estatus
    return unless validacion[:msg] == 'Búsqueda exacta'
    return unless validacion[:estatus]
    return if validacion[:taxon].estatus == 2
    taxon = validacion[:taxon]
    estatus = taxon.especies_estatus     # Checa si existe alguna sinonimia

    if estatus.length == 1  # Encontro el valido y solo es uno, como se esperaba
      begin  # Por si ya no existe ese taxon, suele pasar!
        taxon_valido = Especie.find(estatus.first.especie_id2)
        # Asigna el taxon valido al taxon original
        self.validacion[:taxon_valido] = taxon_valido
        self.validacion[:msg] = 'Búsqueda exacta, era un sinónimo'
      rescue
        self.validacion[:estatus] = false
        self.validacion[:msg] = 'No hay un taxon valido para la coincidencia'
      end

    else  # No existe el valido o hay mas de uno >.>!
      self.validacion[:estatus] = false
      self.validacion[:msg] = 'No hay un taxon valido para la coincidencia'
    end
  end

  # Para quitar los sinonimos y ver si la unica coincidencia es valida
  def quita_sinonimos_coincidencias
    return unless validacion[:taxones].present?
    validos = []

    validacion[:taxones].each do |taxon|
      validos << taxon if taxon.estatus == 2
    end

    if validos.count == 1
      self.validacion[:taxones] = nil

      if validacion[:msg] == 'Existe más de una búsqueda exacta'
        self.validacion = { estatus: true, taxon: validos.first, msg: 'Búsqueda exacta' }
      else
        self.validacion = { estatus: true, taxon: validos.first, msg: 'Búsqueda similar' }
      end
    end
  end

  # Si es una sola coincidencia trata de quitar subgeneros si existieran para dar la busqueda exacta
  def quita_subgeneros
    return unless validacion[:estatus]
    return unless validacion[:msg] == 'Búsqueda similar'

    if nombre_cientifico == validacion[:taxon].nombre_cientifico.gsub(/\([^()]*\)/, ' ').squeeze(" ").strip
      self.validacion = { estatus: true, taxon: validacion[:taxon], msg: 'Búsqueda exacta' }
    end
  end

end