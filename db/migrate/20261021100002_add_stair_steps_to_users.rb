class AddStairStepsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stair_steps, :integer
  end
end
