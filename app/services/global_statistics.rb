class GlobalStatistics
  def global_rankings
    Player.includes(:match_players).map do |player|
      {
        player: player,
        name: player.name,
        total_kills: player.total_kills,
        total_deaths: player.total_deaths,
        kd_ratio: player.kd_ratio.round(2),
        matches_played: player.matches.count,
        matches_won: player.matches_won
      }
    end.sort_by { |stat| -stat[:total_kills] }
  end

  def top_players(limit = 10)
    global_rankings.first(limit)
  end

  def player_stats(player)
    {
      player: player,
      total_kills: player.total_kills,
      total_deaths: player.total_deaths,
      kd_ratio: player.kd_ratio.round(2),
      matches_played: player.matches.count,
      matches_won: player.matches_won,
      average_kills_per_match: average_stat(player, :kills_count),
      average_deaths_per_match: average_stat(player, :deaths_count),
      match_history: player_match_history(player)
    }
  end

  def most_used_weapons
    # future optimization
    # query can become heavy when made with millions of records and many weapons, index or some sort of count cacheing could help
    Kill.where(world_kill: false)
      .group(:weapon)
      .count
      .sort_by { |_, count| -count }
  end

  def total_matches
    Match.count
  end

  def total_players
    Player.count
  end

  def total_kills
    MatchPlayer.sum(:kills_count)
  end

  def total_deaths
    MatchPlayer.sum(:deaths_count)
  end

  def summary
    {
      total_matches: total_matches,
      total_players: total_players,
      total_kills: total_kills,
      total_deaths: total_deaths,
      average_kills_per_match: (total_kills.to_f / total_matches).round(2),
      top_players: top_players(5),
      most_used_weapons: most_used_weapons.first(5)
    }
  end

  private

  def average_stat(player, stat)
    return 0.0 if player.match_players.empty?

    total = player.match_players.sum(stat)
    count = player.match_players.count
    (total.to_f / count).round(2)
  end

  def player_match_history(player)
    player.match_players.includes(:match).map do |mp|
      {
        match_id: mp.match.match_id,
        started_at: mp.match.started_at,
        kills: mp.kills_count,
        deaths: mp.deaths_count,
        score: mp.score,
        kd_ratio: mp.kd_ratio.round(2),
        won: mp.match.winner == player
      }
    end
  end
end
