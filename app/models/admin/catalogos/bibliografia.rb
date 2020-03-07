class Admin::Bibliografia < Bibliografia

  scope :autocompleta, ->(termino) { select(:id, :cita_completa).where("#{Bibliografia.attribute_alias(:cita_completa)} LIKE ? COLLATE utf8_general_ci", "%#{termino}%").limit(10) }

end
