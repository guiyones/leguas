class AddLoadKgToWalks < ActiveRecord::Migration[8.1]
  def change
    add_column :walks, :load_kg, :decimal, precision: 4, scale: 1
  end
end
