class CreateStairSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :stair_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.date :climbed_on, null: false
      t.integer :climbs, null: false
      t.decimal :load_kg, precision: 4, scale: 1
      t.string :note

      t.timestamps
    end

    add_index :stair_sessions, [ :user_id, :climbed_on ]
  end
end
