class UpdateUsuariosSetLocaleDefault < ActiveRecord::Migration[5.1]
  def up
    change_column "#{CONFIG.bases.ev}.usuarios", :locale, :string, default: 'es'
  end

  def down
    change_column "#{CONFIG.bases.ev}.usuarios", :locale, :string, default: nil
  end
end