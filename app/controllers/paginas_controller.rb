# Este controlador tiene la finalidad de hacer contenido por paginas, ej la lista de invasoras
class PaginasController < ApplicationController
  skip_before_action :set_locale
  layout false, :only => [:exoticas_invasoras_paginado]

  # La pagina cuando entran por get
  def exoticas_invasoras
    lee_csv
    @tabla_exoticas[:cabeceras] = ['', 'Nombre científico', 'Familia', 'Grupo', 'Ambiente',
                                   'Origen', 'Presencia', 'Estatus', 'Instrumento legal', 'Ficha']
  end

  # La resultados que provienen del paginado
  def exoticas_invasoras_paginado
    lee_csv
    render partial: 'exoticas_invasoras'
  end


  protected

  def lee_csv
    @tabla_exoticas = {}
    @tabla_exoticas[:datos] = []

    opciones_posibles
    opciones_seleccionadas

    file = File.dirname(__FILE__) << '/../../public/exoticas-invasoras.csv'
    exoticas_url = '/pdfs/exoticas_invasoras/'
    instrumentos_url = '/pdfs/exoticas_invasoras/instrumentos_legales/'
    exoticas_dir = File.dirname(__FILE__) << '/../../public' << exoticas_url
    inst_dir = File.dirname(__FILE__) << '/../../public' << instrumentos_url

    csv_text = File.read(file)
    csv = CSV.parse(csv_text, :headers => true)

    @por_pagina = 30
    @pagina = params[:pagina].present? ? params[:pagina].to_i : 1
    @totales = 0  # Cuenta los que han pasado el filtro

    csv.each_with_index do |row, index|
      next unless condiciones_filtros(row)

      @totales+= 1
      next if (@por_pagina*(@pagina-1)+1) > @totales || @por_pagina*@pagina < @totales  # Por si esta fuera de rango del paginado

      pdf = false
      datos = []

      if row['enciclovida_id'].present?
        t = Especie.find(row['enciclovida_id'])
        datos << t.adicional.try(:foto_principal)
        datos << t

        if familia = t.ancestors.left_joins(:categoria_taxonomica).where("#{CategoriaTaxonomica.attribute_alias(:nombre_categoria_taxonomica)} = 'familia'")
          datos << familia.first.nombre_cientifico
        else
          datos << nil
        end

        datos << row['Grupo']

        pdf_path = exoticas_dir + t.nombre_cientifico + '.pdf'
        pdf = exoticas_url + t.nombre_cientifico + '.pdf' if File.exist?(pdf_path)

      else
        # Para poner una foto de la carpeta, si es que tiene
        if row['Creditos Fotos'].present?
          nombre = "#{row['Nombre científico']}.jpg"
          foto = Rails.root.join('public','fotos_invasoras', nombre)

          if File.exists?(foto)
            foto_url = "/fotos_invasoras/#{nombre}"
            datos << foto_url
          else
            datos << nil
          end
        else
          datos << nil
        end

        datos << row['Nombre científico']
        datos << row['Familia']
        datos << row['Grupo']

        pdf_path = exoticas_dir + row['Nombre científico'] + '.pdf'
        pdf = exoticas_url + row['Nombre científico'] + '.pdf' if File.exist?(pdf_path)

      end  # End con id enciclovida

      datos << row['Ambiente']
      #datos << row['DistribuciónNativa']
      #datos << row['DistribuciónInvasora']
      datos << row['Origen']
      datos << row['Presencia']
      datos << row['Estatus']

      instrumentos = []
      if row['Regulada por otros instrumentos'].present?
        row['Regulada por otros instrumentos'].split('/').each do |inst|
          inst = inst.strip
          pdf_inst_path = inst_dir + inst + '.pdf'
          if File.exist?(pdf_inst_path)
            pdf_inst = instrumentos_url + inst + '.pdf'
            instrumentos << {nombre: inst, pdf: pdf_inst}
          else  # Por si esta mal renombrado el pdf
            instrumentos << {nombre: 'No existe pdf', pdf: nil}
          end
        end  # End each do
      end

      datos << instrumentos
      pdf.present? ? datos << pdf : datos << nil

      @tabla_exoticas[:datos] << datos

    end  # End each row

    # El paginado
    @paginas = @totales%@por_pagina == 0 ? @totales/@por_pagina : (@totales/@por_pagina) +1
  end

  def opciones_posibles
    @select = {}
    @select[:grupos] = ['Algas y protoctistas', 'Anfibios', 'Arácnidos', 'Aves', 'Crustáceos', 'Hongos', 'Insectos', 'Mamíferos', 'Moluscos', 'Otros invertebrados', 'Peces', 'Plantas', 'Reptiles', 'Virus y bacterias']
    @select[:origenes] = ['Criptogénica', 'Exótica', 'Nativa']
    @select[:presencias] = ['Ausente', 'Confinado', 'Indeterminada', 'Por confirmar', 'Presente']
    @select[:instrumentos_legales] = ['Acuerdo enfermedades y plagas SAGARPA 2016', 'Acuerdo especies exóticas SEMARNAT', 'MOD NOM-005-FITO-1995', 'NOM-016-SEMARNAT-2013', 'NOM-043-FITO-1999']
    @select[:ambientes] = ['Dulceacuícola', 'Marino', 'Parásito', 'Parásito Dulceacuícola', 'Parásito Marino', 'Párasito Terrestre', 'Salobre', 'Terrestre']  # Se necesita estandarizar
    @select[:estatus] = ['Invasora']
    @select[:fichas] = ['Sí', 'No']
  end

  def opciones_seleccionadas
    @selected = {}
    if params[:grupo].present?
      @selected[:grupo] = {}
      @selected[:grupo][:valor] = params[:grupo]
      @selected[:grupo][:nom_campo] = 'Grupo'
    end

    if params[:origen].present?
      @selected[:origen] = {}
      @selected[:origen][:valor] = params[:origen]
      @selected[:origen][:nom_campo] = 'Origen'
    end

    if params[:presencia].present?
      @selected[:presencia] = {}
      @selected[:presencia][:valor] = params[:presencia]
      @selected[:presencia][:nom_campo] = 'Presencia'
    end

    if params[:instrumento].present?
      @selected[:instrumento] = {}
      @selected[:instrumento][:valor] = params[:instrumento]
      @selected[:instrumento][:nom_campo] = 'Regulada por otros instrumentos'
    end

    if params[:ambiente].present?
      @selected[:ambiente] = {}
      @selected[:ambiente][:valor] = params[:ambiente]
      @selected[:ambiente][:nom_campo] = 'Ambiente'
    end

    if params[:estatus].present?
      @selected[:estatus] = {}
      @selected[:estatus][:valor] = params[:estatus]
      @selected[:estatus][:nom_campo] = 'Estatus'
    end

    if params[:ficha].present?
      @selected[:ficha] = {}
      @selected[:ficha][:valor] = params[:ficha]
      @selected[:ficha][:nom_campo] = 'Ficha'
    end
  end

  def condiciones_filtros(row)
    @selected.each do |campo, v|  # Compara que las condiciones se cumplan
      if v[:nom_campo] == 'Ficha'
        if v[:valor] == 'Sí'
          if row[v[:nom_campo]].blank?
            return false
          end
        else
          if row[v[:nom_campo]].present?
            return false
          end
        end

      else
        if row[v[:nom_campo]].blank?  # Si es vacio entonces no coincide
          return false
        end

        val_params = v[:valor].split('/')
        val_excel = row[v[:nom_campo]].gsub('/ ', '/').split('/')
        return false unless (val_params & val_excel).present?
      end
    end  # End @selected.each

    true
  end

end