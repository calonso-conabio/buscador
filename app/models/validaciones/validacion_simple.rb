class ValidacionSimple < Validacion

  attr_accessor :lista

  COLUMNAS_OBLIGATORIAS = {nombre_cientifico: ['nombre_cientifico']}
  COLUMNAS_OPCIONALES = {}
  COLUMNAS_DEFAULT = %w(nombre_original nombre_valido_enciclovida mensaje)

  def initialize
    self.lista = []
    super
  end

  def valida_archivo
    super

    sheet.parse(cabecera).each_with_index do |f, index|
      next if index == 0
      self.nombre_cientifico = f['nombre_cientifico']
      encuentra_por_nombre
      quita_sinonimos_coincidencias if validacion[:taxones].present?
      taxon_estatus
      self.recurso_validado << validacion.merge({nombre_orig: f['nombre_cientifico']})
    end

    resp = guarda_excel

    if resp[:estatus]
      self.excel_url = resp[:excel_url]
      EnviaCorreo.excel(self).deliver
    end
  end

  def valida_lista
    return {estatus: false, msg: 'La lista no puede ser vacia.'} unless lista.present?

    self.lista = lista.split("\r\n")
    return {estatus: false, msg: 'Solo pueden ser 200 observaciones para validar en el área de texto, si requieres validar más por favor sube un archivo.'} if lista.length > 200

    lista.each do |nombre|
      self.nombre_cientifico = nombre
      encuentra_por_nombre
      quita_sinonimos_coincidencias if validacion[:taxones].present?
      taxon_estatus

      self.recurso_validado << validacion.merge({nombre_orig: nombre})
    end

    {estatus: true}
  end

  # Exporta la informacion, para que desde la lista guarde el excel
  def guarda_excel
    lista = Lista.new
    lista.columnas_array = (COLUMNAS_DEFAULT + Lista::COLUMNAS_GENERALES + Lista::COLUMNAS_FOTOS)
    lista.taxones = recurso_validado
    lista.to_excel(asignar: true)  # Para que asigne los valores de las columnas
  end
end