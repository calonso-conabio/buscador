class Eol

  attr_accessor :especie

  def api_eol(params = {})

    page = params[:page] || 1

    begin
      rest_client = RestClient::Request.execute(method: :get, url: "https://eol.org/api/search/1.0.json?q=#{especie.nombre_cientifico}&page=#{page}&key=&exact=true", timeout: 20)
      res = JSON.parse(rest_client)

      res["results"].each do |result|
        if result["title"] == especie.nombre_cientifico
          if p=especie.proveedor
            p.eol_id = result["id"]
            p.save

          else
            Proveedor.new(eol_id: result["id"], especie_id: especie.id).save

          end
          return {estatus: true, resultados: result}
        end
      end

      {estatus: false, msg: "Esta busqueda no contiene resultados"}
    end
  rescue => e
    {estatus: false, msg: e}
  end


  def eol_n
    return { estatus: false, msg: 'No existe el proveedor'} unless n = especie.proveedor
    return { estatus: false, msg: 'No existe en EOL'} unless n.eol_id.present?

    resultado = []

    (1..5).to_a.each { |p|

      begin
        #puts "https://eol.org/api/pages/1.0/#{n.eol_id}.json?details=false&images_per_page=0&videos_per_page=0&sounds_per_page=0&maps_page=0&texts_per_page=75&references=true&taxonomy=false&vetted=1&language=en&texts_page=#{p}"
        rest_client = RestClient::Request.execute(method: :get, url: "https://eol.org/api/pages/1.0/#{n.eol_id}.json?details=false&images_per_page=0&videos_per_page=0&sounds_per_page=0&maps_page=0&texts_per_page=75&references=true&taxonomy=false&vetted=1&language=en&texts_page=#{p}", timeout: 20)
        res = JSON.parse(rest_client)

        break if res["taxonConcept"]["dataObjects"].blank?
        res["taxonConcept"]["dataObjects"].each do |resulta|
          if resulta["language"] == "es"
            resultado << resulta["description"]
          end
        end
      end
    }
    if resultado.present?
      return {estatus: true, resultados: resultado}
    else
     return { estatus: false, msg: 'No hay descripcion a mostrar'}
        end
    rescue => e
    {estatus: false, msg: e}
    end


  def initialize(params={})
    self.especie = params[:especie]
  end
end

