class CreateWalks < ActiveRecord::Migration[8.1]
  def change
    create_table :walks do |t|
      t.references :user, null: false, foreign_key: true
      t.date :walked_on, null: false
      t.decimal :km, precision: 5, scale: 2, null: false
      t.string :note

      t.timestamps
    end

    add_index :walks, [ :user_id, :walked_on ]
  end
end
