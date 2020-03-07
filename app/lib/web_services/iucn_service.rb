class IUCNService

  attr_accessor :datos, :row, :validacion

  # Consulta la categoria de riesgo de un taxon dado
  def consultaRiesgo(opts)
    @iucn = CONFIG.iucn.api
    @token = CONFIG.iucn.token

    url = "#{@iucn}/api/v3/species/#{opts[:nombre].limpiar(tipo: 'ssp')}?token=#{@token}"
    url_escape = URI.escape(url)
    uri = URI.parse(url_escape)
    req = Net::HTTP::Get.new(uri.to_s)
    begin
      res = Net::HTTP.start(uri.host, uri.port, :read_timeout => CONFIG.iucn.timeout ) {|http| http.request(req) }
      jres = JSON.parse(res.body)['result']
      jres[0]['category'] if jres.any?
    rescue => e
      nil
    end
  end

  # Guarda en cache la respuesta del servicio
  def dameRiesgo(opc={})
    resp = Rails.cache.fetch("iucn_#{opc[:id]}", expires_in: eval(CONFIG.cache.iucn)) do
      iucn = consultaRiesgo(opc)
      I18n.t("iucn_ws.#{iucn.estandariza}", :default => iucn) if iucn.present?
    end

    resp
  end

  # Accede al archivo que contiene los assessments y la taxonomia dentro de la carpeta versiones_IUCN
  # NOTAS: Este archivo se baja de la pagina de IUCN y hay que unir el archivo de asessments con el de taxonomy y guardarlo bajo public/IUCN
  def actualiza_IUCN(archivo)
    csv_path = Rails.root.join('public', 'IUCN', archivo)
    bitacora.puts 'Nombre científico en IUCN,Categoría en IUCN,Nombre en CAT,IdCAT,Estatus nombre,IdCAT válido,Nombre válido CAT,observaciones'
    return unless File.exists? csv_path

    CSV.foreach(csv_path, :headers => true) do |r|
      self.row = r
      self.datos = [row['scientificName'], row['redlistCategory'], nil, nil, nil, nil, nil, nil]  # Se inicializa la respuesta vacia

      v = Validacion.new

      if row['subpopulationName'].present?  # Quita la zona del nombre cientifico ... bien IUCN
        v.nombre_cientifico = row['scientificName'].gsub(row['subpopulationName'], '')
      else
        v.nombre_cientifico = row['scientificName']
      end

      v.nombre_cientifico = v.nombre_cientifico.gsub('ssp.', 'subsp.')
      v.encuentra_por_nombre

      self.validacion = v.validacion
      self.datos[7] = validacion[:msg]

      if validacion[:estatus]
        valida_extras  # Solo un resultado y al menos fue coincidencia
      else
        if validacion[:taxones].present?  # Mas de un resultado
          if datos[7] == 'Existe más de una búsqueda exacta'
            cuantos_encontro = 0

            validacion[:taxones].each do |taxon|
              validacion[:taxon] = taxon
              if valida_extras  # Encontro el verdadero de entre las coincidencias
                self.datos[7] = 'Búsqueda exacta'
                cuantos_encontro+= 1
                break
              end
            end  # End each taxones

            sin_coincidencias if cuantos_encontro == 0

          else  # Si es busqueda similar con multiples coincidencias
            cuantos_encontro = []

            validacion[:taxones].each do |taxon|  # Descartando los que no son de la categoria o del phylum/division
              validacion[:taxon] = taxon
              next unless misma_categoria?
              next unless mismo_phylum?

              cuantos_encontro << taxon
            end  # End each taxones

            if cuantos_encontro.length == 0
              sin_coincidencias
            elsif cuantos_encontro.length == 1
              sin_coincidencias
              validacion[:taxon] = cuantos_encontro.first
              self.datos[7] = 'Búsqueda similar'
              valida_extras
            else
              sin_coincidencias
              self.datos[7] = "Existe más de una búsqueda similar: #{validacion[:taxones].map{ |t| t.scat.catalogo_id }.join('|')}"
            end

          end  # End si existe mas de una busqueda exacta con multiples coincidencias

        end
      end

      bitacora.puts datos.join(',')
    end

    bitacora.close
  end


  private

  # Bitacora especial para catalogos, antes de correr en real, pasarsela
  def bitacora
    log_path = Rails.root.join('log', 'validacion_IUCN', Time.now.strftime('%Y-%m-%d_%H%m') + '_IUCN.csv')
    @@bitacora ||= File.new(log_path, 'a+')
  end

  # Comparo si el phylum/division es la misma para busquedas similares
  def mismo_phylum?
    validacion[:taxon].asigna_categorias

    if validacion[:taxon].x_reino.estandariza == 'animalia'  # Es phylum
      return true if validacion[:taxon].x_phylum.estandariza == row['phylumName'].estandariza
    else  # De lo contrario es plantae, fungi, etc
      return true if validacion[:taxon].x_division.estandariza == row['phylumName'].estandariza
    end

    self.datos[7] = 'Sin coincidencias'
    false
  end

  # Valida que la categoria taxonomica sea la misma
  def misma_categoria?
    categorias = { 'subspecies' => 'subespecie', 'subspecies-plantae' => 'subespecie', 'variety' => 'variedad' }

    categoria = if row['infraType'].blank?
                  'especie'
                else
                  categorias[row['infraType'].estandariza]
                end

    cat_taxon = validacion[:taxon].categoria_taxonomica.nombre_categoria_taxonomica.estandariza

    unless cat_taxon == categoria
      self.datos[7] = 'Sin coincidencias'
      return false
    end

    true
  end

  # Asigna el nombre valido en caso de ser un sinonimo
  def dame_el_valido
    if validacion[:taxon].estatus == 1
      if taxon_valido = validacion[:taxon].dame_taxon_valido
        validacion[:taxon] = taxon_valido
        self.datos[5] = validacion[:taxon].scat.catalogo_id
        self.datos[6] = validacion[:taxon].nombre_cientifico
        self.datos[7] = 'Búsqueda exacta, era un sinónimo'
        true
      else
        self.datos[7] = 'Es un sinónimo y hubo problemas al encontrar el válido'
        false
      end

    else
      self.datos[5] = validacion[:taxon].scat.catalogo_id
      self.datos[6] = validacion[:taxon].nombre_cientifico
      true
    end
  end

  # Valida el nombre y categoría taxonomica
  def valida_extras
    return false unless misma_categoria?
    return false unless mismo_phylum?

    self.datos[2] = validacion[:taxon].nombre_cientifico
    self.datos[3] = validacion[:taxon].scat.catalogo_id
    self.datos[4] = validacion[:taxon].estatus == 2 ? 'Válido/Aceptado' : 'Sinónimo'

    return true if ['Búsqueda similar'].include?(datos[7])
    return dame_el_valido if ['Búsqueda exacta', 'Existe más de una búsqueda exacta'].include?(datos[7])
  end

  def sin_coincidencias
    self.datos[2] = nil
    self.datos[3] = nil
    self.datos[4] = nil
    self.datos[5] = nil
    self.datos[6] = nil
    self.datos[7] = 'Sin coincidencias'
  end

end

