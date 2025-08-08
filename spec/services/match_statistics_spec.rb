require 'rails_helper'

RSpec.describe MatchStatistics do
  let(:match) { create(:match) }
  let(:player1) { create(:player, name: 'Roman') }
  let(:player2) { create(:player, name: 'Nick') }
  let(:player3) { create(:player, name: 'Marcus') }

  before do
    create(:match_player, match: match, player: player1, kills_count: 10, deaths_count: 2)
    create(:match_player, match: match, player: player2, kills_count: 5, deaths_count: 8)
    create(:match_player, match: match, player: player3, kills_count: 7, deaths_count: 4)

    create(:kill, match: match, killer: player1, victim: player2, weapon: 'M16')
    create(:kill, match: match, killer: player1, victim: player3, weapon: 'M16')
    create(:kill, match: match, killer: player1, victim: player2, weapon: 'AK47')
    create(:kill, match: match, killer: player3, victim: player1, weapon: 'AWP')
    create(:kill, :world_kill, match: match, victim: player2, weapon: 'DROWN')
  end

  subject(:statistics) { described_class.new(match) }

  describe '#rankings' do
    it 'returns players ordered by kills' do
      rankings = statistics.rankings

      expect(rankings.first[:player].name).to eq('Roman')
      expect(rankings.second[:player].name).to eq('Marcus')
      expect(rankings.third[:player].name).to eq('Nick')
    end

    it 'includes correct statistics for each player' do
      rankings = statistics.rankings
      roman_stats = rankings.first

      expect(roman_stats[:kills]).to eq(10)
      expect(roman_stats[:deaths]).to eq(2)
      expect(roman_stats[:score]).to eq(8)
      expect(roman_stats[:kd_ratio]).to eq(5.0)
    end
  end

  describe '#winner' do
    it 'returns the player with most kills' do
      expect(statistics.winner).to eq(player1)
    end
  end

  describe '#most_deadly_weapon' do
    it 'returns the weapon with most kills' do
      expect(statistics.most_deadly_weapon).to eq('M16')
    end

    it 'excludes world kill weapons' do
      5.times { create(:kill, :world_kill, match: match, weapon: 'DROWN') }
      expect(statistics.most_deadly_weapon).to eq('M16')
    end
  end

  describe '#total_kills' do
    it 'returns total number of player kills' do
      expect(statistics.total_kills).to eq(4)
    end

    it 'excludes world kills' do
      create(:kill, :world_kill, match: match, weapon: 'FALL')
      expect(statistics.total_kills).to eq(4)
    end
  end

  describe '#total_world_kills' do
    it 'returns total number of world kills' do
      expect(statistics.total_world_kills).to eq(1)
    end
  end

  describe '#match_summary' do
    it 'returns complete match information' do
      summary = statistics.match_summary

      expect(summary).to include(
        match_id: match.match_id,
        started_at: match.started_at,
        ended_at: match.ended_at,
        duration: match.duration,
        total_kills: 4,
        total_world_kills: 1,
        winner: player1,
        most_deadly_weapon: 'M16'
      )
    end

    it 'includes rankings in summary' do
      summary = statistics.match_summary
      expect(summary[:rankings]).to be_present
      expect(summary[:rankings].size).to eq(3)
    end
  end

  describe '#player_weapon_stats' do
    it 'returns weapon usage statistics per player' do
      weapon_stats = statistics.player_weapon_stats(player1)

      expect(weapon_stats['M16']).to eq(2)
      expect(weapon_stats['AK47']).to eq(1)
    end

    it 'returns empty hash for player with no kills' do
      weapon_stats = statistics.player_weapon_stats(player2)
      expect(weapon_stats).to be_empty
    end
  end

  describe '#kill_feed' do
    it 'returns kills in chronological order' do
      feed = statistics.kill_feed

      expect(feed).to be_an(Array)
      expect(feed.size).to eq(5)
      expect(feed.first[:occurred_at]).to be <= feed.last[:occurred_at]
    end

    it 'includes world kills in feed' do
      feed = statistics.kill_feed
      world_kill = feed.find { |k| k[:world_kill] }

      expect(world_kill).to be_present
      expect(world_kill[:killer]).to eq('WORLD')
    end
  end
end
