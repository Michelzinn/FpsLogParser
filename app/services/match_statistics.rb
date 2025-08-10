class MatchStatistics
  attr_reader :match

  def initialize(match)
    @match = match
  end

  def rankings
    match.match_players.includes(:player).order(kills_count: :desc).map do |mp|
      {
        player: mp.player,
        name: mp.player.name,
        kills: mp.kills_count,
        deaths: mp.deaths_count,
        score: mp.score,
        kd_ratio: mp.kd_ratio,
        awards: mp.awards || []
      }
    end
  end

  def winner
    match.winner
  end

  def most_deadly_weapon
    match.kills
      .where(world_kill: false)
      .group(:weapon)
      .count
      .max_by { |_, count| count }
      &.first
  end

  def total_kills
    match.kills.where(world_kill: false).count
  end

  def total_world_kills
    match.kills.where(world_kill: true).count
  end

  def match_summary
    {
      match_id: match.match_id,
      started_at: match.started_at,
      ended_at: match.ended_at,
      duration: match.duration,
      total_kills: total_kills,
      total_world_kills: total_world_kills,
      winner: winner,
      most_deadly_weapon: most_deadly_weapon,
      rankings: rankings
    }
  end

  def player_weapon_stats(player)
    match.kills
      .where(killer: player, world_kill: false)
      .group(:weapon)
      .count
  end

  def winner_favorite_weapon
    return nil if winner.blank?

    weapon_counts = match.kills
      .where(killer: winner, world_kill: false)
      .group(:weapon)
      .count

    return nil if weapon_counts.empty?

    weapon_counts.max_by { |_, count| count }&.first
  end

  def kill_feed
    match.kills.includes(:killer, :victim).order(:occurred_at).map do |kill|
      {
        killer: kill.killer&.name || "WORLD",
        victim: kill.victim.name,
        weapon: kill.weapon,
        occurred_at: kill.occurred_at,
        world_kill: kill.world_kill?
      }
    end
  end
end
