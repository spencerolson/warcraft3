class CreateUnits < ActiveRecord::Migration[5.1]
  def change
    create_table :units do |t|
      t.string :name
      t.string :armor_type
      t.string :attack_type
      t.string :race
      t.integer :tier
      t.string :can_attack
      t.text :notes, default: ''
      t.boolean :immune_to_magic

      t.timestamps
    end
    add_index :units, :name, unique: true
  end
end
