class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.string :match_id
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    add_index :matches, :match_id, unique: true
  end
end
