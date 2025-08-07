class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :player

  validates :match_id, presence: true
  validates :player_id, presence: true, uniqueness: { scope: :match_id }
  validates :kills_count, numericality: { greater_than_or_equal_to: 0 }
  validates :deaths_count, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_default_counts

  def score
    kills_count - deaths_count
  end

  def kd_ratio
    return 0.0 if kills_count == 0 && deaths_count == 0
    return kills_count.to_f if deaths_count == 0
    kills_count.to_f / deaths_count
  end

  private

  def set_default_counts
    self.kills_count ||= 0
    self.deaths_count ||= 0
  end
end