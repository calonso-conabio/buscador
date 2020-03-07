json.extract! admin_bibliografia, :id, :autor, :anio, :titulo_publicacion, :titulo_sub_publicacion, :editorial_pais_pagina, :numero_volumen_anio, :editores_compiladores, :isbnissn, :observaciones, :created_at, :updated_at
json.url admin_bibliografia_url(admin_bibliografia, format: :json)
