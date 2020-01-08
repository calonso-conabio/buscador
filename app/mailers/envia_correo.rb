class EnviaCorreo < Devise::Mailer
  default from: 'noreply@conabio.gob.mx'

  # Metodos adicionales
  def excel(validacion)
    @ruta_excel = validacion.excel_url
    @correos = validacion.correo
    mail(:to => enviar_a?(validacion.correo), :subject => "EncicloVida: validacion/descarga de #{validacion.nombre_archivo}")
  end

  def respuesta_comentario(comentario)
    completa_datos_comentario(comentario)
    @correos = @comentario_root.correo
    mail(:to => enviar_a?(@comentario_root.correo), :subject => 'EncicloVida: Respuesta a comentario')
  end

  def comentario_resuelto(comentario)
    completa_datos_comentario(comentario)
    @correos = @comentario_root.correo
    mail(:to => enviar_a?(@comentario_root.correo), :subject => 'EncicloVida: Comentario resuelto')
  end

  def confirmacion_comentario(comentario)
    completa_datos_comentario(comentario)
    @correos = @comentario_root.correo
    mail(:to => enviar_a?(@comentario_root.correo), :subject => 'EncicloVida: Comentario recibido')
  end

  def confirmacion_comentario_general(comentario)
    completa_datos_comentario(comentario)
    @correos = @comentario_root.correo
    mail(:to => enviar_a?(@comentario_root.correo), :subject => 'EncicloVida: Comentario recibido')
  end

  def descargar_taxa(ruta, correo, original_url=nil)
    @ruta = ruta
    @correos = correo
    @original_url = original_url
    mail(:to => enviar_a?(correo), :subject => 'EncicloVida: Descargar taxa')
  end

  def avisar_responsable_contenido(comentario,correos)
    completa_datos_comentario(comentario)
    @correos = correos
    mail(:to => enviar_a?(correos), :subject => 'EncicloVida: Te ha sido asignado un comentario para solucionar')
  end

  private

  def completa_datos_comentario(comentario)
    @comentario = comentario
    @comentario_root = @comentario.root
    @comentario.completa_info(@comentario_root.usuario_id)

    if t = @comentario.especie
      @nombre_cientifico = t.nombre_cientifico

      if a = t.adicional
        @nombre_comun = a.nombre_comun_principal
      end
    end

    @comentario_root.completa_info(@comentario_root.usuario_id)
    @created_at = @comentario_root.created_at.strftime('%d-%m-%y_%H-%M-%S')
  end

  # Método que revisa si estamos en producción... y que envía solo a los desarrolladores o correos de pruebas en development
  def enviar_a?(correos)

    correos = [correos] unless correos.is_a? Array

    if Rails.env.production?
      return correos.join(',')
    else
      correos.keep_if do |c|
        c.include?("ggonzalez") || c.include?("calonso") || c.include?("albertoglezba") || c.include?("mailinator")
      end
      correos << CONFIG.correo_admin unless correos.any?
      return correos.join(',')
    end
  end

end
