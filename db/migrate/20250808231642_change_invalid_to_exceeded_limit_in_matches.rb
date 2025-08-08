class ChangeInvalidToExceededLimitInMatches < ActiveRecord::Migration[8.0]
  def change
    rename_column :matches, :invalid, :exceeded_player_limit
  end
end
