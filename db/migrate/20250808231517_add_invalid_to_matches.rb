class AddInvalidToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :invalid, :boolean, default: false, null: false
    add_index :matches, :invalid
  end
end
