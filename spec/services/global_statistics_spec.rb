require 'rails_helper'

RSpec.describe GlobalStatistics do
  let!(:player1) { create(:player, name: 'Roman') }
  let!(:player2) { create(:player, name: 'Nick') }
  let!(:player3) { create(:player, name: 'Marcus') }
  let!(:player4) { create(:player, name: 'John') }

  let!(:match1) { create(:match) }
  let!(:match2) { create(:match) }
  let!(:invalid_match) { create(:match, exceeded_player_limit: true) }

  before do
    create(:match_player, match: match1, player: player1, kills_count: 10, deaths_count: 2)
    create(:match_player, match: match1, player: player2, kills_count: 5, deaths_count: 8)

    create(:match_player, match: match2, player: player1, kills_count: 7, deaths_count: 3)
    create(:match_player, match: match2, player: player3, kills_count: 12, deaths_count: 1)

    create(:match_player, match: invalid_match, player: player1, kills_count: 20, deaths_count: 0)
    create(:match_player, match: invalid_match, player: player4, kills_count: 15, deaths_count: 5)
  end

  subject(:statistics) { described_class.new }

  describe '#global_rankings' do
    it 'excludes invalid matches from statistics' do
      rankings = statistics.global_rankings
      roman = rankings.find { |r| r[:name] == 'Roman' }
      expect(roman[:total_kills]).to eq(17)
      expect(roman[:total_deaths]).to eq(5)
      expect(roman[:matches_played]).to eq(2)

      john = rankings.find { |r| r[:name] == 'John' }
      expect(john[:total_kills]).to eq(0)
      expect(john[:total_deaths]).to eq(0)
      expect(john[:matches_played]).to eq(0)
    end

    it 'returns players ordered by total kills' do
      rankings = statistics.global_rankings

      expect(rankings.first[:name]).to eq('Roman')
      expect(rankings.first[:total_kills]).to eq(17)
      expect(rankings.first[:total_deaths]).to eq(5)
      expect(rankings.first[:matches_played]).to eq(2)
    end

    it 'calculates global KD ratio correctly' do
      rankings = statistics.global_rankings
      roman = rankings.find { |r| r[:name] == 'Roman' }

      expect(roman[:kd_ratio]).to eq(3.4)
    end

    it 'handles players with no matches' do
      create(:player, name: 'NewPlayer')
      rankings = statistics.global_rankings
      new_player = rankings.find { |r| r[:name] == 'NewPlayer' }

      expect(new_player[:matches_played]).to eq(0)
      expect(new_player[:total_kills]).to eq(0)
      expect(new_player[:total_deaths]).to eq(0)
    end

    it 'includes all players' do
      rankings = statistics.global_rankings
      expect(rankings.size).to eq(4)
    end
  end

  describe '#top_players' do
    it 'returns specified number of top players' do
      top = statistics.top_players(2)

      expect(top.size).to eq(2)
      expect(top.first[:name]).to eq('Roman')
      expect(top.second[:name]).to eq('Marcus')
    end
  end

  describe '#player_stats' do
    it 'returns complete statistics for a specific player' do
      stats = statistics.player_stats(player1)

      expect(stats[:player]).to eq(player1)
      expect(stats[:total_kills]).to eq(17)
      expect(stats[:total_deaths]).to eq(5)
      expect(stats[:matches_played]).to eq(2)
      expect(stats[:kd_ratio]).to eq(3.4)
      expect(stats[:average_kills_per_match]).to eq(8.5)
      expect(stats[:average_deaths_per_match]).to eq(2.5)
    end

    it 'includes match history without won field' do
      stats = statistics.player_stats(player1)

      expect(stats[:match_history]).to be_an(Array)
      expect(stats[:match_history].size).to eq(2)
      expect(stats[:match_history].first).to include(
        :match_id,
        :kills,
        :deaths,
        :score,
        :kd_ratio
      )
      expect(stats[:match_history].first).not_to have_key(:won)
    end
  end

  describe '#most_used_weapons' do
    before do
      create(:kill, match: match1, killer: player1, victim: player2, weapon: 'M16')
      create(:kill, match: match1, killer: player1, victim: player2, weapon: 'M16')
      create(:kill, match: match1, killer: player1, victim: player2, weapon: 'AK47')
      create(:kill, match: match2, killer: player1, victim: player3, weapon: 'M16')
    end

    it 'returns weapons ordered by usage count' do
      weapons = statistics.most_used_weapons

      expect(weapons.first).to eq([ 'M16', 3 ])
      expect(weapons.second).to eq([ 'AK47', 1 ])
    end

    it 'excludes world kill weapons' do
      create(:kill, :world_kill, match: match1, weapon: 'DROWN')
      weapons = statistics.most_used_weapons

      expect(weapons.map(&:first)).not_to include('DROWN')
    end
  end

  describe '#total_matches' do
    it 'returns total number of valid matches only' do
      expect(statistics.total_matches).to eq(2)
    end
  end

  describe '#total_players' do
    it 'returns total number of unique players' do
      expect(statistics.total_players).to eq(4)
    end
  end

  describe '#total_kills' do
    it 'excludes kills from invalid matches' do
      expect(statistics.total_kills).to eq(34)
    end
  end

  describe '#total_deaths' do
    it 'excludes deaths from invalid matches' do
      expect(statistics.total_deaths).to eq(14)
    end
  end

  describe '#summary' do
    it 'returns complete global statistics excluding invalid matches' do
      summary = statistics.summary

      expect(summary).to include(
        total_matches: 2,
        total_players: 4,
        total_kills: 34,
        total_deaths: 14
      )

      expect(summary[:top_players]).to be_present
      expect(summary[:most_used_weapons]).to be_an(Array)
    end
  end
end
