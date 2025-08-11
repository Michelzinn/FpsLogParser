class LogParser
  include Dry::Monads[:result]

  MAX_PLAYERS_PER_MATCH = 20

  attr_reader :content

  def initialize(content)
    @content = content
    @current_match = nil
    @match_players = {}
    @errors = []
  end

  def parse
    return Failure(:empty_content) if content.blank?

    lines_processed = 0
    @completed_matches_found = []

    content.each_line do |line|
      next if line.strip.empty?

      process_line(line.strip)
      lines_processed += 1
    end

    return Failure(:no_valid_lines) if lines_processed == 0

    if @completed_matches_found.any?
      return Failure({ error: :already_processed, message: "Log contains already processed matches: #{@completed_matches_found.uniq.join(', ')}" })
    end

    Success({ processed: lines_processed, errors: @errors.presence }.compact_blank)
  end

  private

  def process_line(line)
    timestamp, event = extract_timestamp_and_event(line)
    return if timestamp.blank? || event.blank?

    case event
    when /New match (\d+) has started/
      match_id = $1
      handle_match_start(match_id, timestamp)
    when /Match (\d+) has ended/
      match_id = $1
      handle_match_end(match_id, timestamp)
    when /<WORLD> killed (.+) by (.+)/
      victim = $1
      weapon = $2
      handle_kill(nil, victim, weapon, timestamp, world_kill: true)
    when /(.+) killed (.+) using (.+)/
      killer = $1
      victim = $2
      weapon = $3
      handle_kill(killer, victim, weapon, timestamp)
    else
      @errors << "Unknown event format: #{line}"
    end
  end

  def extract_timestamp_and_event(line)
    match = line.match(/^(\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}) - (.+)$/)
    return nil if match.blank?

    timestamp = DateTime.strptime(match[1], "%d/%m/%Y %H:%M:%S")
    event = match[2]

    [ timestamp, event ]
  end

  def handle_match_start(match_id, timestamp)
    existing_match = Match.find_by(match_id: match_id)
    already_completed = existing_match&.ended_at.present?

    if already_completed
      @completed_matches_found << match_id
      @current_match = nil
      return
    end

    @current_match = existing_match || Match.create!(match_id: match_id, started_at: timestamp)
    @match_players = {}
  end

  def handle_match_end(match_id, timestamp)
    return if @current_match.blank? || @current_match.match_id != match_id

    player_count = @current_match.players.count
    invalid_match = player_count > MAX_PLAYERS_PER_MATCH

    if invalid_match
      @current_match.update(ended_at: timestamp, exceeded_player_limit: true)
      @errors << "Match #{match_id} exceeded player limit: #{player_count} players (max #{MAX_PLAYERS_PER_MATCH})"
    else
      assign_awards
      @current_match.update(ended_at: timestamp)
    end

    @current_match = nil
  end

  def handle_kill(killer_name, victim_name, weapon, timestamp, world_kill: false)
    return if @current_match.blank?

    victim = find_or_create_player(victim_name)
    killer = world_kill ? nil : find_or_create_player(killer_name)

    Kill.create!(match: @current_match, killer:, victim:, weapon:, occurred_at: timestamp, world_kill:)

    update_player_stats(killer, :kill) if killer.present?
    update_player_stats(victim, :death)
  end

  def find_or_create_player(name)
    Player.find_or_create_by(name: name.strip) # remove whitespaces in case regex parses weird names
  end

  def update_player_stats(player, event_type)
    return if @current_match.blank?

    # caches it in @match_players to avoid multiple DB calls
    match_player = @match_players[player.id] ||= MatchPlayer.find_or_create_by(
      match: @current_match,
      player: player
    )

    case event_type
    when :kill
      match_player.increment!(:kills_count)
    when :death
      match_player.increment!(:deaths_count)
    end
  end

  def assign_awards
    return if @current_match.blank?

    winner = @current_match.match_players.max_by { |player| player.score }
    return if winner.blank?

    awards = []

    awards << "Deathless Victory" if winner.deaths_count == 0

    winner.update(awards:) if awards.any?
  end
end
