class Geoportal::Municipio < GeoportalAbs

  self.primary_key = 'munid'

  scope :campos_min, -> { select('cve_mun AS region_id, cve_ent AS parent_id, municipio AS nombre_region, munid AS region_id_se').order(municipio: :asc) }
  scope :centroide, -> { select('st_x(st_centroid(the_geom)) AS long, st_y(st_centroid(the_geom)) AS lat') }
  scope :geojson_select, -> { select('ST_AsGeoJSON(the_geom) AS geojson') }
  scope :campos_geom, -> { centroide.geojson_select }
  scope :geojson, ->(region_id, parent_id) { geojson_select.where(cve_mun: region_id, cve_ent: parent_id) }


  private

  def nombre_publico
    "#{municipio}, #{I18n.t("estados.#{estado.estandariza.gsub('-', '_')}")}"
  end

  def asigna_redis
    asigna_redis_id
    self.redis[:data] = {}
    self.redis[:term] = I18n.transliterate(municipio.limpia.downcase)
    self.redis[:score] = 100
    self.redis[:data][:id] = munid
    self.redis[:data][:nombre] = nombre_publico

    redis.deep_stringify_keys!
  end

  # Arma el ID de redis
  def asigna_redis_id
    # El 2 inicial es para saber que es un region
    # El 1 en la segunda posicion denota que es un estado
    # Y despues se ajusta a 8 digitos el numero de estado, para dar un total de 10 digitos
    self.redis = {} unless redis.present?
    self.redis["id"] = "21#{munid.to_s.rjust(8,'0')}".to_i
  end

end