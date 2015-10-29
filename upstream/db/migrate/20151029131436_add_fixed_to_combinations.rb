class AddFixedToCombinations < ActiveRecord::Migration
  def change
    add_column :combinations, :fixed, :boolean, :default => false
  end
end
