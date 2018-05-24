class PezCriterio < ActiveRecord::Base

  establish_connection(:peces)
  self.table_name='peces_criterios'
  self.primary_keys = :especie_id, :criterio_id

  belongs_to :pez, class_name: 'Pez', foreign_key: :especie_id
  belongs_to :criterio

end