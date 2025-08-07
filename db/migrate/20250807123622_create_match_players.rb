class CreateMatchPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :match_players do |t|
      t.references :match, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :kills_count, default: 0, null: false
      t.integer :deaths_count, default: 0, null: false

      t.timestamps
    end

    add_index :match_players, [:match_id, :player_id], unique: true
  end
end