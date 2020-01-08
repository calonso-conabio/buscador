# require 'net/http'
class BhlService

  def rescuApi(nombre)
    puts "bhlService , nombre a buscar: #{nombre}\n"
    url = "https://www.biodiversitylibrary.org/api3?op=PublicationSearch&searchterm=#{nombre}&searchtype=F&page=1&apikey=7e82aa4f-7314-4452-869c-9b2664459541&format=json"
    url_escape = URI.escape(url)
    uri = URI.parse(url_escape)
    req = Net::HTTP::Get.new(uri.to_s)

    begin
      res = Net::HTTP.get_response(uri)
    rescue => e
      nil
    end
     return res.body
  end
end
