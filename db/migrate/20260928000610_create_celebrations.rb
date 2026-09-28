class CreateCelebrations < ActiveRecord::Migration[8.1]
  def change
    create_table :celebrations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false

      t.timestamps
    end

    add_index :celebrations, [ :user_id, :key ], unique: true
  end
end
