class AddAirUnitToUnits < ActiveRecord::Migration[5.1]
  def change
    add_column :units, :air_unit, :boolean, default: false
  end
end
