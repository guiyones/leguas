class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :goal_km, precision: 4, scale: 1, null: false

      t.timestamps
    end

    add_index :missions, [ :user_id, :date ], unique: true
  end
end
