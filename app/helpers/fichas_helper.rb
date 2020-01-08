module FichasHelper

  def dameCategoriasDeRiesgo
    html = ''

    def iteraCategorias(legislacion)
      html = "<p><strong>#{legislacion.nombreLegislacion}:</strong> #{legislacion.estatusLegalProteccion}</p>"
      html << "<p>Anotacion: #{legislacion.infoAdicional.a_HTML}</p>" if legislacion.infoAdicional.present?
      html
    end

    return html unless @ficha[:legislaciones].any?
    html << '<h4 class="text-center text-primary">Categorías de riesgo nacional/internacional</h4>'

    @ficha[:legislaciones].each do |legislacion|
      html << iteraCategorias(legislacion)
    end

    html.html_safe
  end

end