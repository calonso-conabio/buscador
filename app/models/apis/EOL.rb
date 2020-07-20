class Eol

  attr_accessor :especie

  def api_eol(params = {})

    page = params[:page] || 1

    begin
      rest_client = RestClient::Request.execute(method: :get, url: "https://eol.org/api/search/1.0.json?q=#{especie.nombre_cientifico}&page=#{page}&key=&exact=true", timeout: 20)
      res = JSON.parse(rest_client)

      res["results"].each do |result|
        if result["title"] == especie.nombre_cientifico
          if p = especie.proveedor
            p.eol_id = result[""]
          else
            Proveedor.new(eol_id: "", especie_id: especie.id).save
          end
          return {estatus: true, resultados: res["results"][0]}
        end
      end

      {estatus: false, msg: "Esta busqueda no contiene resultados"}

    rescue => e
      {estatus: false, msg: e}
    end
  end


  def initialize(params={})
    self.especie = params[:especie]
  end

end


