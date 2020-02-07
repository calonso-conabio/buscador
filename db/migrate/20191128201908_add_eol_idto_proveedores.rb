class AddEolIdtoProveedores < ActiveRecord::Migration[5.1]
  def change
    add_column :proveedores, :eol_id, :integer
  end
end
