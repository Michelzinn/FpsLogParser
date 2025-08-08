class LogParser
  include Dry::Monads[:result]

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

    content.each_line do |line|
      next if line.strip.empty?

      process_line(line.strip)
      lines_processed += 1
    end

    return Failure(:no_valid_lines) if lines_processed == 0

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
      handle_world_kill(victim, weapon, timestamp)
    when /(.+) killed (.+) using (.+)/
      killer = $1
      victim = $2
      weapon = $3
      handle_player_kill(killer, victim, weapon, timestamp)
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
    @current_match = Match.find_or_create_by(match_id: match_id) do |match|
      match.started_at = timestamp
    end
    @match_players = {}
  end

  def handle_match_end(match_id, timestamp)
    return if @current_match.blank? || @current_match.match_id != match_id

    @current_match.update(ended_at: timestamp)
    @current_match = nil
  end

  def handle_world_kill(victim_name, weapon, timestamp)
    return if @current_match.blank?

    victim = find_or_create_player(victim_name)

    Kill.create!(
      match: @current_match,
      killer: nil,
      victim: victim,
      weapon: weapon,
      occurred_at: timestamp,
      world_kill: true
    )

    update_player_stats(victim, :death)
  end

  def handle_player_kill(killer_name, victim_name, weapon, timestamp)
    return if @current_match.blank?

    killer = find_or_create_player(killer_name)
    victim = find_or_create_player(victim_name)

    Kill.create!(
      match: @current_match,
      killer: killer,
      victim: victim,
      weapon: weapon,
      occurred_at: timestamp,
      world_kill: false
    )

    update_player_stats(killer, :kill)
    update_player_stats(victim, :death)
  end

  def find_or_create_player(name)
    Player.find_or_create_by(name: name.strip) # remove whitespaces in case regex parses weird names
  end

  def update_player_stats(player, event_type)
    return if @current_match.blank?

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
end
