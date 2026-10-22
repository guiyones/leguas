class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :km, precision: 5, scale: 2, null: false
      t.integer :duration_s
      t.string :note
      t.json :trace
      t.string :trace_source

      t.timestamps
    end

    add_reference :walks, :route, foreign_key: { on_delete: :nullify }
  end
end
