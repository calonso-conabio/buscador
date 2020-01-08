class MacaulayService

  def dameMedia_nc(taxonNC, type, page=1, min_page_size = 20)
    cornell = CONFIG.cornell.api

    url = "#{cornell}sciName=#{taxonNC.limpiar.gsub(' ','+')}&assetFormatCode=#{type}&taxaLocale=es&page=#{page}&pageSize=#{min_page_size}"
    url_escape = URI.escape(url)
    uri = URI.parse(url_escape)
    req = Net::HTTP::Get.new(uri.to_s)
    req['key'] = CONFIG.cornell.key

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      jres = JSON.parse(res.body) if res.body.present?
      #Si la especie es correcta pero ya no hay más media q mostrar, no hay error, solo un body vacío
      jres = [{msg: "No hay más resultados para #{taxonNC}", length: res.header['content-length']}] if res.header['content-length'] == "0"
      #Si la  especie no es encontrada, Macaulay arroja un 404 :D
      jres = [{msg: "No se encontró coincidencia para #{taxonNC}", code: res.code}] if res.code == "404"
      jres
    rescue => e
      [{msg: "Hubo algun error en la solicitud: #{e} \n intente de nuevo más tarde"}]
    end
  end

end

