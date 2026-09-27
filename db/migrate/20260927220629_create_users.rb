class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :name
      t.string :avatar
      t.decimal :daily_goal_km, precision: 4, scale: 1, default: 3

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
