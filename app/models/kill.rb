class Kill < ApplicationRecord
  belongs_to :match
  belongs_to :killer, class_name: 'Player', optional: true
  belongs_to :victim, class_name: 'Player'

  validates :weapon, presence: true
  validates :occurred_at, presence: true
  validates :match_id, presence: true
  validates :victim_id, presence: true

  scope :by_player, ->(player) { where(killer: player) }
  scope :world_kills, -> { where(world_kill: true) }

  def world_kill?
    world_kill || killer_id.nil?
  end
end