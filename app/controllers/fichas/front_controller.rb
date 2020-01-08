class Fichas::FrontController < Fichas::FichasController

  before_action :set_taxon
  layout false

  #  - - - - - - - - * * Rutas de información de especie (Según su id) * *  - - - - - - - -
  # Clasificación y descripción de la especie
  def clasificacion_y_descripcion_de_especie # especieId
    @nombre_comun = @taxon.nombreComun
    @legislacion = @taxon.legislaciones.first
    @sinonimo = @taxon.sinonimos.first

    render json: {
        taxon: @taxon,
        nombre_comun: @nombre_comun,
        legislacion: @legislacion,
        sinonimo: @sinonimo
    }
  end

  # Distribución de la especie
  def distribucione_de_la_especie # especieId
    @distribucion = @taxon.distribuciones.first
    @endemica = @taxon.endemicas.first
    @habitat = @taxon.habitats.first

    render json: {
        taxon: @taxon,
        distribucion: @distribucion,
        endemica: @endemica,        habitat: @habitat
    }
  end


  # Tipo de ambiente en donde se desarrolla la especie
  def ambiente_de_desarrollo_de_especie

    @habitat = @taxon.habitats.first
    @tipoClima = @habitat.tipoclima
    @suelo = @habitat.suelo
    @geoforma = @habitat.geoforma
    @ecorregion = @habitat.ecorregion.first
    @ecosistema = @habitat.ecosistema.first
    #@cat_eacorregionwwf = Cat_Ecorregionwwf.find_by(IdEcorregion: @ecorregion.ecorregionId)
    @habitatAntropico = @habitat.habitatAntropico

    render json: {
        taxon: @taxon,
        habitat: @habitat,
        tipoClima: @tipoClima,
        suelo: @suelo,
        geoforma: @geoforma,
        ecorregion: @ecorregion,
        ecosistema: @ecosistema,
        habitatAntropico: @habitatAntropico
    }
  end

  # IV. Biología de la especie
  def biologia_de_la_especie
    # Obtener el id de especie
    @habitat = @taxon.habitats.first
    @historiaNatural = @taxon.historiaNatural
    @demografiaAmenazas = @taxon.demografiaAmenazas.first
    @infoReproduccion = @historiaNatural.get_info_reproduccion

    render json: {
        taxon: @taxon,
        habitat: @habitat,
        historiaNatural: @historiaNatural,
        demografiaamenazas: @demografiaamenazas,
        infoReproduccion: @infoReproduccion
    }
  end

  # V. Ecología y demografía de la especie
  def ecologia_y_demografia_de_especie
    # Obtener el id de especie
    @demograAmenazas = @taxon.demografiaAmenazas.first
    @interaccion = @demograAmenazas.interaccion

    render json: {
        taxon: @taxon,
        demograAmenazas: @demograAmenazas,
        interaccion: @interaccion
    }
  end

  # VI. Genética de la especie
  def genetica_de_especie
    @historianatural = @taxon.historiaNatural

    render json: {
        historianatural: @historianatural
    }
  end

  # VII. Importancia de la especie
  def importancia_de_especie
    @historiaNatural = @taxon.historiaNatural
    @culturaUsos = @historiaNatural.culturaUsos

    render json: {
        historianatural: @historianatural,
        culturaUsos: @culturaUsos
    }
  end

  # VIII. Estado de conservación de la especie
  def estado_de_conservacion_de_especie
    @conservacion = @taxon.conservacion.first
    @demografiaAmenazas = @taxon.demografiaAmenazas.first
    @amenazaDirecta = @demografiaAmenazas.amenazaDirecta.first

    render json: {
        amenazaDirecta: @amenazaDirecta,
        demografiaAmenazas: @demografiaAmenazas,
        conservacion: @conservacion
    }
  end

  # IX. Especies prioritarias para la conservación
  def especies_prioritarias_para_conservacion
    # Obtener el id de especie
    render json: { taxon: @taxon }
  end

  # X. Necesidades de información
  def necesidades_de_informacion
    # Obtener el id de especie
    render json: { taxon: @taxon }
  end

  def show
    especie = @taxon.especie
    especie.asigna_categorias

    @sin_info_msj = 'Sin información disponible'

    # A partir de la especie, acceder a:
    # I. Clasificación y descripción de la especie
    @nombre_comun = @taxon.nombreComun
    @legislacion = @taxon.legislaciones || Fichas::Legislacion.new
    @sinonimo = @taxon.sinonimos.first

    # II. Distribución de la especie
    @distribucion = @taxon.distribuciones.first || Fichas::Distribucion.new
    @endemica = @taxon.endemicas.first || Fichas::Endemica.new

    @habitat = @taxon.habitats.first || Fichas::Habitat.new
    # III. Tipo de ambiente en donde se desarrolla la especie
    @tipoClima = @habitat.tipoclima
    @suelo = @habitat.suelo
    @geoforma = @habitat.geoforma
    @ecorregion = @habitat.ecorregion.first
    @ecosistema = @habitat.ecosistema.first
    #@cat_eacorregionwwf = Cat_Ecorregionwwf.find_by(IdEcorregion: @ecorregion.ecorregionId)
    @habitatAntropico = @habitat.habitatAntropico

    # IV. Biología de la especie
    @demografiaAmenazas = @taxon.demografiaAmenazas.first || Fichas::Demografiaamenazas.new
    # V. Ecología y demografía de la especie
    @interaccion = @demografiaAmenazas.interaccion
    @amenazaDirecta = @demografiaAmenazas.amenazaDirecta.first

    # VI. Genética de la especie
    @historiaNatural = @taxon.historiaNatural || Fichas::Historianatural.new
    @infoReproduccion = @historiaNatural.get_info_reproduccion

    # VII. Importancia de la especie
    @culturaUsos = @historiaNatural.culturaUsos.first


    # VIII. Estado de conservación de la especie
    @conservacion = @taxon.conservacion.first || Fichas::Conservacion.new

    # IX. Especies prioritarias para la conservación
    # 

    # X. Necesidades de información
    # 

    # XI. Metadatos:
    @metadato = @taxon.metadatos.first

    if @metadato && @asociado = @metadato.asociado.first
      @organizacion = @asociado.organizacion
      @responsable = @asociado.responsable
      @puesto = @asociado.puesto
      @contacto = @asociado.contacto.first

      if @ciudad = @contacto.ciudad
        @pais = @ciudad.pais
      end
    end

    # XII. Referencias: (Agregado)
    @referencias = @taxon.referenciasBibliograficas

    @ficha = {
        taxon: @taxon, especie: especie,
        # I. Clasificación y descripción de la especie
        edad_peso_largo: @taxon.dame_edad_peso_largo,
        nombre_comun: @nombre_comun, legislaciones: @legislacion, sinonimo: @sinonimo,
        # II. Distribución de la especie
        distribucion: @distribucion, endemica: @endemica, habitat: @habitat,
        # III. Tipo de ambiente en donde se desarrolla la especie
        tipoClima: @tipoClima, suelo: @suelo, geoforma: @geoforma, ecorregion: @ecorregion, ecosistema: @ecosistema, cat_eacorregionwwf: @cat_eacorregionwwf,
        # IV. Biología de la especie
        historiaNatural: @historiaNatural, demografiaamenazas: @demografiaamenazas, infoReproduccion: @infoReproduccion,
        # V. Ecología y demografía de la especie
        interaccion: @interaccion,
        # VI. Genética de la especie
        # VII. Importancia de la especie
        culturaUsos: @culturaUsos,
        # VIII. Estado de conservación de la especie
        amenazaDirecta: @amenazaDirecta, conservacion: @conservacion,
        # IX. Especies prioritarias para la conservación
        # X. Necesidades de información
        # XI. Metadatos
        metadato: @metadato, asociado: @asociado, organizacion: @organizacion, responsable: @responsable, puesto: @puesto, contacto: @contacto, ciudad: @ciudad, pais: @pais,
        # XII. Referencias: (Agregado)
        referencias: @referencias
    }

    respond_to do |format|
      format.html
      format.json { render json: @ficha }
    end
  end



  private

  def set_taxon
    @taxon = Fichas::Taxon.where(IdCat: params[:id]).first  # Obtener el id de especie
  end

end
