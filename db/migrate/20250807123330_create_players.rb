class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name

      t.timestamps
    end
    add_index :players, :name, unique: true
  end
end
