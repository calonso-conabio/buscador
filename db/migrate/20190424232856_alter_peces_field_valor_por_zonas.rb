class AlterPecesFieldValorPorZonas < ActiveRecord::Migration[5.1]
  def up
    change_column "#{CONFIG.bases.pez}.peces", :valor_zonas, :string, limit: 7, default: 'ssssss1'
  end

  def down
    change_column "#{CONFIG.bases.pez}.peces", :valor_zonas, :string, limit: 6, default: 'ssssss'
  end
end