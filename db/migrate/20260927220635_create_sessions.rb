class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.datetime :last_active_at
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
    add_index :sessions, :token, unique: true
  end
end
