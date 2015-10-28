class CreatePendingCombinations < ActiveRecord::Migration
  def change
    create_table :pending_combinations do |t|
      t.integer :owner_id
      t.integer :combination_id
      t.integer :new_device_id
      t.string :new_version
      t.text :comment
      t.boolean :completed
      t.timestamps null: false
    end
  end
end
