class Match < ApplicationRecord
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players
  has_many :kills, dependent: :destroy

  validates :match_id, presence: true, uniqueness: true
  validates :started_at, presence: true

  scope :ordered, -> { order(started_at: :desc) }
  scope :valid_matches, -> { where(exceeded_player_limit: false) }

  def duration
    return nil if ended_at.blank?
    (ended_at - started_at).to_i
  end

  def winner
    match_players.order(kills_count: :desc).first&.player
  end

  def active?
    ended_at.nil?
  end
end
