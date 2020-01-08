class Estadistica < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.ev}.estadisticas"

  has_many :especie_estadisticas, class_name: 'EspecieEstadistica', inverse_of: :estadistica

  # Estadisticas que no se incluirán en la visualizacion
  ESTADISTICAS_QUE_NO = [8, 9, 10, 12, 1, 2, 3, 22, 23, 18]
  # Secciones en las que se dividen las estadísticas
  SECCIONES_ESTADISTICAS = ["Fotos", "Videos", "Audio", "Fichas", "Nombres comunes", "Observaciones", "Ejemplares", "Mapas"]

end
