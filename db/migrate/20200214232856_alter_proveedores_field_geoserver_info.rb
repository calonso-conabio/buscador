class AlterProveedoresFieldGeoserverInfo < ActiveRecord::Migration[5.1]
  def up
    change_column "#{CONFIG.bases.ev}.proveedores", :geoserver_info, :text
    Proveedor.update_all("geoserver_info=NULL")
  end

  def down
    change_column "#{CONFIG.bases.ev}.proveedores", :geoserver_info, :string
  end
end