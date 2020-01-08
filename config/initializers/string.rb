class String
  # Quita simbolos raros y quita los terminos con punto que estan abajo de especies y subgenero
  def limpiar(ssp = false)
    return self unless self.present?

    # Para poner ssp. como esta en NaturaLista y el Banco de Imagenes
    if ssp
      self.limpia.gsub(/\([^()]*\)/, ' ').gsub(/( f\. | var\. | subf\. | subvar\. )/, ' ').gsub(/ subsp\. /, ' ssp. ').strip.gsub(/\s+/,' ')
    else
      self.limpia.gsub(/\([^()]*\)/, ' ').gsub(/( subsp\. | f\. | var\. | subf\. | subvar\. )/, ' ').strip.gsub(/\s+/,' ')
    end
  end

  # Quita simbolos raros
  def limpia
    return self unless self.present?
    self.gsub(/(\r\n|\r|\n)/, '').gsub('"', '\"').gsub("\t", ' ').strip.gsub(/\s+/,' ')
  end

  # Para cuando se quiere consultar un web service
  def limpia_ws(bdi=false)
    self.limpiar(bdi).limpia
  end

  def limpia_csv
    return self unless self.present?
    self.gsub(/(\r\n|\r|\n)/, '').gsub('"', '""').gsub("\t", ' ').strip.gsub(/\s+/,' ')
  end

  # Escapa la comilla simple por dos comillas simples, para que SQL Server no marque error
  def limpia_sql
    self.gsub("'", "''")
  end

  def codifica64
    Base64.encode64(self)
  end

  def decodifica64
    # Retorna directo el json si es diferente a estos inicios de cadena codificados
    return self.force_encoding('UTF-8') if self[0..1] != 'W3' && self[0..1] != 'ey'
    decoded = Base64.decode64(self)
    decoded.force_encoding('UTF-8')
  end

  # Sobre escribe el metodo para poder convertir las palabras que empiezan con acento
  def capitalize
    return self unless self.present?
    self.sub(/^(.)/) { $1.mb_chars.capitalize }
  end

  def estandariza
    sin_acentos.limpia.parameterize
  end

  def sin_acentos
    I18n.transliterate(self).strip.downcase
  end

  # Metodo para asegurarse de parsear bien un HTML o un texto
  def a_HTML
    # Verificar si hay información que mostrar
    if self.present?
      # Verificar que sea texto lo que se va a analizar
      if self.is_a? String
        #Asegurar que el fragmento html tenga los "< / >"'s cerrados
        Nokogiri::HTML.fragment(self).to_html.html_safe
      else
        self.to_s
      end
    else
      ''
    end
  end

end

