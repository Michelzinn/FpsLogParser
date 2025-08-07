class Player < ApplicationRecord
  has_many :match_players, dependent: :destroy
  has_many :matches, through: :match_players
  has_many :kills_as_killer, class_name: 'Kill', foreign_key: 'killer_id', dependent: :destroy
  has_many :kills_as_victim, class_name: 'Kill', foreign_key: 'victim_id', dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def total_kills
    match_players.sum(:kills_count)
  end

  def total_deaths
    match_players.sum(:deaths_count)
  end

  def kd_ratio
    return 0.0 if total_kills == 0 && total_deaths == 0
    return total_kills.to_f if total_deaths == 0
    total_kills.to_f / total_deaths
  end

  def matches_won
    matches.select { |match| match.winner == self }.count
  end
end