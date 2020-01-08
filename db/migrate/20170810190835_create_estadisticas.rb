class CreateEstadisticas < ActiveRecord::Migration[5.1]
  def up
    create_table :estadisticas do |t|
      t.string :descripcion_estadistica
      t.timestamps
    end

    descripciones = ["Visitas a la especie o grupo",
                     "Número de especies",
                     "Número de especies e inferiores",
                     "Nombres comunes de NaturaLista",
                     "Nombres comunes de CONABIO",
                     "Fotos en NaturaLista",
                     "Fotos en el Banco de Imágenes de CONABIO",
                     "Fotos en EOL",
                     "Fotos en Wikimedia",
                     "Fotos en flickr",
                     "Fichas revisadas de CONABIO",
                     "Fichas en revisión de CONABIO",
                     "Fichas de EOL-español",
                     "Fichas de EOL-ingles",
                     "Fichas de Wikipedia-español",
                     "Fichas de Wikipedia-ingles",
                     "Ejemplares en el SNIB",
                     "Ejemplares en el SNIB (aVerAves)",
                     "Observaciones en NaturaLista (grado de investigación)",
                     "Observaciones en NaturaLista (grado casual)",
                     "Mapas de distribución", "Número de especies validas", "Número de especies e inferiores validas",
                     "Fotos en Tropicos",
                     "Fotos en Maccaulay",
                     "Videos en Maccaulay",
                     "Audio en Maccaulay" ]

    descripciones.each do |x|
      Estadistica.create(:descripcion_estadistica => x)
    end
  end

  def down
    drop_table :estadisticas
  end
end
