require 'rest-client'
require 'json'

class Tropicos_Service

  def initialize(options = {})
    @service_name = 'Tropicos'
    @server = options[:server] || "#{IP}:#{PORT}" # después del puerto, termina con '/'
    @timeout = options[:timeout] || 8
    @debug = options[:debug] || false
    Rails.logger.debug "[DEBUG] Inicializar el servicio: #{@service_name}"
  end

  # Función que obtiene el NameId de la especie a buscar según su nombre común
  def get_id_name(name)

    format = 'json'
    search_type = 'exact'

    query = "#{CONFIG.tropicos.api}Search?name=#{name.strip.gsub(' ', '+')}&type=#{search_type}&apikey=#{CONFIG.tropicos.key}&format=#{format}"
    Rails.logger.debug "[DEBUG] Se realizará la busqueda del id de: '#{name}' porque no estuvo en la base de datos, URL: #{query}"

    begin
      # Invocamos el servicio y la respuesta será un: RestClient::Response
      pre_resu = RestClient.get(query)
      # Aun que no se encuentre la el nombre:
      resu = JSON.parse(pre_resu.body) if pre_resu.body.present?
      Rails.logger.debug "[DEBUG] La respuesta del nombreID es: #{resu.to_s}"
      resu = [{msg: "no se encontró coincidencia para #{name}"}] if resu[0]["Error"].present?
      resu

    rescue => e
      # el error 404, sólo sale cuando la URL está mal
      [{msg: "hubo algun error en la solicitud: #{e} \n intente de nuevo más tarde"}]
    end
  end

  # Función que obtiene las imagenes de X especie
  def get_media(id_name)

    format = 'json'

    # Para búsqueda de imagenes
    query = "#{CONFIG.tropicos.api}#{id_name}/Images?apikey=#{CONFIG.tropicos.key}&format=#{format}"
    Rails.logger.debug "[DEBUG] Se realizará la busqueda de imagenes del id: #{id_name}, URL: #{query}"

    begin
      # Invocamos el servicio y la respuesta será un: RestClient::Response
      pre_resu = RestClient.get(query)
      # Aun que no se encuentre la el nombre:
      resu = JSON.parse(pre_resu.body) if pre_resu.body.present?
      resu

    rescue => e
      # el error 404, sólo sale cuando la URL está mal
      [{msg: "Hubo algun error en la solicitud: #{e} \n intente de nuevo más tarde"}]
    end
  end


  # Función para agregar a la tabla Proveedor
  def agerga_proveedor_id_tropicos(especie, proveedor = false)
    # Se invoca cuando no existe aún la especie en proveedores ni el tropico_id, buscarlo invocando el servicio:
    name_id = get_id_name(especie.nombre_cientifico)

    if name_id[0][:msg].present?
      return nil
    else
      # Si existió la especie:
      Proveedor.create(especie_id: especie.id, tropico_id: name_id[0]['NameId'])
      return name_id[0]['NameId']
    end
  end

end