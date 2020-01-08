class Metamares::GraficasM

  attr_accessor :datos

  def initialize(params={})
    self.datos = params[:tipo_dato] || {}
  end

  # Gráfica por año de publicacion contra campo de investigación
  def grafica1
    q = Metamares::Proyecto.select('COUNT(campo_investigacion) AS totales, publicacion_fecha, campo_investigacion').
        left_joins(:dato).where("publicacion_fecha IS NOT NULL AND publicacion_fecha > '2005-01-01'").group('publicacion_fecha, campo_investigacion').order('publicacion_fecha')

    q.each do |d|
      anio = d.publicacion_fecha.strftime("%Y").to_i

      while datos[anio].nil?
        datos[anio] = {} unless datos[anio].present?
        datos[anio][:year] = anio

        datos[anio][:variableA] = 0
        datos[anio][:variableB] = 0
        datos[anio][:variableC] = 0
        datos[anio][:variableD] = 0
        datos[anio][:variableE] = 0
        datos[anio][:variableF] = 0
        datos[anio][:variableG] = 0
        datos[anio][:variableH] = 0
      end

      case d.campo_investigacion
      when 'Aquaculture'
        datos[anio][:variableA] = d.totales
      when 'Conservation'
        datos[anio][:variableB] = d.totales
      when 'Ecology'
        datos[anio][:variableC] = d.totales
      when 'Fisheries'
        datos[anio][:variableD] = d.totales
      when 'Oceanography'
        datos[anio][:variableE] = d.totales
      when 'Sociology'
        datos[anio][:variableF] = d.totales
      when 'Tourism'
        datos[anio][:variableG] = d.totales
      when 'Other'
        datos[anio][:variableH] = d.totales
      end
    end

    self.datos = datos.map{ |year,valor| valor }
  end

  # Gráfica por área, region o localidad
  def grafica2
    max_score = 0
    primero = true

    q = Metamares::RegionM.select('COUNT(*) AS totales, nombre_region').group(:nombre_region).order('totales DESC').where('nombre_region IS NOT NULL')

    q.each_with_index do |d, index|
      if primero
        max_score+= d.totales
        primero = false
      end

      while d.nombre_region.nil?
        d.nombre_region = 'NA'
      end

      self.datos << { id: d.nombre_region.estandariza, order: index + 1, score: d.totales*100/ max_score, weight: 1, label: d.nombre_region, totales: d.totales }
    end
  end

end