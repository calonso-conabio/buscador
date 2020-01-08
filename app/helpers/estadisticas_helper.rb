module EstadisticasHelper

  # Función uqe devolverá una lista de estadísticas para seleccionar
  def selectEstadisticas
    el_select = '<h6><strong>Estadísticas a mostrar</strong></h6>'
    el_select << '<select class="selectpicker form-control" id="showEstadisticas" data-live-search="true" title="Selecciona las estadísticas a mostrar (ninguno para mostrar todas)" data-selected-text-format="count > 0" name="showEstadisticas[]" multiple>'
    Estadistica::SECCIONES_ESTADISTICAS.each do |seccion|
      el_select += "<optgroup label='#{seccion}'>"
      Estadistica.all.each do |estadistica|
        # Saltar estadísticas que no se usarán
        next if Estadistica::ESTADISTICAS_QUE_NO.index(estadistica.id)
        if estadistica.descripcion_estadistica.include?(seccion)
          nombre = estadistica.descripcion_estadistica.gsub("#{seccion} ","").gsub("de ","").gsub("en ","").gsub("el ","")
          el_select << "<option value='#{estadistica.id}'>#{nombre}</option>"
        end
      end
      el_select << "</optgroup>"
    end
    el_select << '</select>'
    el_select
  end

  def valorResultado
    el_radioB = "<h6><strong>Resultados</strong></h6>"
    el_radioB << "<label class='radio-inline'><input type='radio' name='tipoResultado' value='mayorCero' id='rb_mayorCero' checked /> Mayor a 0</label>"
    el_radioB << "<label class='radio-inline'><input type='radio' name='tipoResultado' value='cero' id='rb_cero' /> Igual a 0</label>"
    el_radioB << "<label class='radio-inline'><input type='radio' name='tipoResultado' value='mayorIgualCero' id='rb_mayorIgualCero' /> Mayor o igual a 0</label>"
    el_radioB
  end

end