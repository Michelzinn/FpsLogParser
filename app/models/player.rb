class Player < ApplicationRecord
  # This match_players relation here is used to cache kills or deaths player had in certain matches to not make queries such as
  # Kill.where(match_id: 1, killer: roman).count which is not efficient on large databases

  has_many :match_players, dependent: :destroy
  has_many :matches, through: :match_players
  has_many :kills_as_killer, class_name: 'Kill', foreign_key: 'killer_id', dependent: :destroy
  has_many :kills_as_victim, class_name: 'Kill', foreign_key: 'victim_id', dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def total_kills
    match_players.joins(:match).where(matches: { exceeded_player_limit: false }).sum(:kills_count)
  end

  def total_deaths
    match_players.joins(:match).where(matches: { exceeded_player_limit: false }).sum(:deaths_count)
  end

  def kd_ratio
    return total_kills.to_f if total_deaths.zero?
    total_kills.to_f / total_deaths
  end

  def matches_won
    matches.where(exceeded_player_limit: false).select { |match| match.winner == self }.count
  end
end
