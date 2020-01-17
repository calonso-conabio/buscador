json.array!(@catalogos) do |catalogo|
  json.extract! catalogo, 
  json.url catalogo_url(catalogo, format: :json)
end