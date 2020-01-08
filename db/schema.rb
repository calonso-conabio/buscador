# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190424232856) do

  create_table "adicionales", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "especie_id", null: false
    t.string "nombre_comun_principal"
    t.string "foto_principal", limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "nombres_comunes", limit: 4294967295
    t.integer "idMillon"
    t.index ["especie_id"], name: "ClusteredIndex-20160801-144106"
    t.index ["nombre_comun_principal"], name: "NonClusteredIndex-20160801-144122", length: { nombre_comun_principal: 191 }
  end

  create_table "bibliografias", id: :integer, default: nil, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.text "observaciones", limit: 4294967295
    t.string "autor", null: false
    t.string "anio", limit: 50, null: false
    t.string "titulo_publicacion", null: false
    t.string "titulo_sub_publicacion"
    t.string "editorial_pais_pagina"
    t.string "numero_volumen_anio"
    t.string "editores_compiladores"
    t.string "isbnissn", limit: 50
    t.text "cita_completa", limit: 4294967295
    t.string "orden_cita_completa", limit: 15
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bitacoras", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "descripcion", limit: 4294967295
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "usuario_id", null: false
  end

  create_table "categorias_contenido", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "nombre", null: false
    t.string "ancestry"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comentarios", primary_key: "idConsecutivo", id: :integer, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
    t.text "comentario", limit: 4294967295, null: false
    t.string "correo"
    t.string "nombre"
    t.integer "especie_id", null: false
    t.integer "usuario_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.integer "estatus", default: 2, null: false
    t.string "ancestry"
    t.datetime "fecha_estatus"
    t.integer "usuario_id2"
    t.integer "categorias_contenido_id", default: 31, null: false
    t.string "institucion"
    t.string "idBak"
    t.string "id", limit: 10, default: ""
  end

  create_table "comentarios_generales", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "comentario_id", limit: 10, null: false
    t.text "subject", limit: 4294967295, null: false
    t.text "commentArray", limit: 4294967295, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comentarios_proveedores", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "comentario_id", limit: 10, null: false
    t.string "proveedor_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", limit: 4294967295, null: false
    t.text "last_error", limit: 4294967295
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "idx_delayed_jobs_queue"
  end

  create_table "especies_estadistica", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "especie_id"
    t.integer "estadistica_id"
    t.integer "conteo", default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["especie_id"], name: "idx_especies_estadistica_especie_id"
    t.index ["estadistica_id"], name: "idx_especies_estadistica_estadistica_id"
  end

  create_table "estadisticas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "descripcion_estadistica"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "listas", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "nombre_lista", null: false
    t.text "columnas", limit: 4294967295
    t.string "formato"
    t.integer "esta_activa", limit: 2, default: 0, null: false
    t.text "cadena_especies", limit: 4294967295
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "usuario_id", null: false
  end

  create_table "proveedores", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "especie_id", null: false
    t.integer "naturalista_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "geoserver_info"
    t.string "tropico_id"
  end

  create_table "relacionCentralizacion", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "id", limit: 50
    t.string "idCAT", limit: 50
    t.string "idMillon", limit: 50
    t.string "idCentralizado", limit: 50
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "nombre_rol", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.string "observaciones"
  end

  create_table "roles_categorias_contenido", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "categorias_contenido_id"
    t.integer "rol_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "session_id", null: false
    t.text "data", limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "usuarios", id: :integer, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
    t.string "nombre", null: false
    t.string "apellido", null: false
    t.string "institucion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "es", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "observaciones"
  end

  create_table "usuarios_especie", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "usuario_id"
    t.integer "especie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "usuarios_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "usuario_id"
    t.integer "rol_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
