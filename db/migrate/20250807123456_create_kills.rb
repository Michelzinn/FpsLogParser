class CreateKills < ActiveRecord::Migration[8.0]
  def change
    create_table :kills do |t|
      t.references :match, null: false, foreign_key: true
      t.references :killer, null: true, foreign_key: { to_table: :players }
      t.references :victim, null: false, foreign_key: { to_table: :players }
      t.string :weapon, null: false
      t.datetime :occurred_at, null: false
      t.boolean :world_kill, default: false

      t.timestamps
    end
  end
end