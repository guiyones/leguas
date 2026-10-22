class AddWorkoutFieldsToWalks < ActiveRecord::Migration[8.1]
  def change
    add_column :walks, :duration_s, :integer
    add_column :walks, :steps, :integer
    add_column :walks, :elevation_gain_m, :integer
  end
end
