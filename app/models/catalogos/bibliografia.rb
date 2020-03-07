class Bibliografia < ActiveRecord::Base

  self.table_name = "#{CONFIG.bases.cat}.Bibliografia"
  self.primary_key = 'IdBibliografia'

  # Los alias con las tablas de catalogos
  alias_attribute :id, :IdBibliografia
  alias_attribute :observaciones, :Observaciones
  alias_attribute :autor, :Autor
  alias_attribute :anio, :Anio
  alias_attribute :titulo_publicacion, :TituloPublicacion
  alias_attribute :titulo_sub_publicacion, :TituloSubPublicacion
  alias_attribute :editorial_pais_pagina, :EditorialPaisPagina
  alias_attribute :numero_volumen_anio, :NumeroVolumenAnio
  alias_attribute :editores_compiladores, :EditoresCompiladores
  alias_attribute :isbnissn, :ISBNISSN
  alias_attribute :cita_completa, :CitaCompleta
  alias_attribute :orden_cita_completa, :OrdenCitaCompleta

  scope :con_especie, ->(id) { where("#{NombreRegionBibliografia.table_name}.#{Especie.attribute_alias(:id)}=?", id).distinct }

end
