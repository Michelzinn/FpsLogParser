require 'rails_helper'

RSpec.describe LogParser do
  describe '#parse' do
    let(:log_content) do
      <<~LOG
        23/04/2019 15:34:22 - New match 11348965 has started
        23/04/2019 15:36:04 - Roman killed Nick using M16
        23/04/2019 15:36:33 - <WORLD> killed Nick by DROWN
        23/04/2019 15:39:22 - Match 11348965 has ended

        23/04/2021 16:14:22 - New match 11348966 has started
        23/04/2021 16:26:04 - Roman killed Marcus using M16
        23/04/2021 16:36:33 - <WORLD> killed Marcus by DROWN
        23/04/2021 16:49:22 - Match 11348966 has ended
      LOG
    end

    subject(:parser) { described_class.new(log_content) }

    describe 'match creation' do
      it 'creates correct number of matches' do
        expect { parser.parse }.to change(Match, :count).by(2)
      end

      it 'sets correct match attributes' do
        parser.parse

        match1 = Match.find_by(match_id: '11348965')
        expect(match1.started_at).to eq(DateTime.parse('23/04/2019 15:34:22'))
        expect(match1.ended_at).to eq(DateTime.parse('23/04/2019 15:39:22'))

        match2 = Match.find_by(match_id: '11348966')
        expect(match2.started_at).to eq(DateTime.parse('23/04/2021 16:14:22'))
        expect(match2.ended_at).to eq(DateTime.parse('23/04/2021 16:49:22'))
      end
    end

    describe 'player creation' do
      it 'creates unique players only' do
        expect { parser.parse }.to change(Player, :count).by(3)
      end

      it 'creates players with correct names' do
        parser.parse

        expect(Player.pluck(:name)).to contain_exactly('Roman', 'Nick', 'Marcus')
      end
    end

    describe 'kill creation' do
      it 'creates correct number of kills' do
        expect { parser.parse }.to change(Kill, :count).by(4)
      end

      it 'creates regular kills correctly' do
        parser.parse

        match = Match.find_by(match_id: '11348965')
        roman = Player.find_by(name: 'Roman')
        nick = Player.find_by(name: 'Nick')

        kill = Kill.find_by(match: match, killer: roman, victim: nick)
        expect(kill).to be_present
        expect(kill.weapon).to eq('M16')
        expect(kill.world_kill).to be false
      end

      it 'creates world kills correctly' do
        parser.parse

        match = Match.find_by(match_id: '11348965')
        nick = Player.find_by(name: 'Nick')

        world_kill = Kill.find_by(match: match, victim: nick, world_kill: true)
        expect(world_kill).to be_present
        expect(world_kill.killer).to be_nil
        expect(world_kill.weapon).to eq('DROWN')
      end
    end

    describe 'match player statistics' do
      it 'calculates kills count correctly' do
        parser.parse

        match1 = Match.find_by(match_id: '11348965')
        roman = Player.find_by(name: 'Roman')

        match_player = MatchPlayer.find_by(match: match1, player: roman)
        expect(match_player.kills_count).to eq(1)
      end

      it 'calculates deaths count correctly' do
        parser.parse

        match1 = Match.find_by(match_id: '11348965')
        nick = Player.find_by(name: 'Nick')

        match_player = MatchPlayer.find_by(match: match1, player: nick)
        expect(match_player.deaths_count).to eq(2)
      end

      it 'does not count world kills as frags' do
        parser.parse

        matches = Match.all
        matches.each do |match|
          match.match_players.each do |mp|
            world_kills = match.kills.world_kills.where(killer: mp.player).count
            expect(world_kills).to eq(0)
          end
        end
      end
    end

    describe 'many informations scenario' do
      let(:complex_log) do
        <<~LOG
          24/04/2020 16:14:22 - New match 11348961 has started
          24/04/2020 16:26:12 - Roman killed Marcus using M16
          24/04/2020 16:35:56 - Marcus killed John using AK47
          24/04/2020 17:12:34 - Roman killed Bryan using M16
          24/04/2020 18:26:14 - Bryan killed Marcus using AK47
          24/04/2020 19:36:33 - <WORLD> killed Marcus by DROWN
          24/04/2020 20:19:22 - Match 11348961 has ended
        LOG
      end

      subject(:complex_parser) { described_class.new(complex_log) }

      it 'handles multiple kills per player' do
        complex_parser.parse

        match = Match.find_by(match_id: '11348961')
        roman = Player.find_by(name: 'Roman')
        marcus = Player.find_by(name: 'Marcus')

        roman_stats = MatchPlayer.find_by(match: match, player: roman)
        expect(roman_stats.kills_count).to eq(2)
        expect(roman_stats.deaths_count).to eq(0)

        marcus_stats = MatchPlayer.find_by(match: match, player: marcus)
        expect(marcus_stats.kills_count).to eq(1)
        expect(marcus_stats.deaths_count).to eq(3)
      end
    end

    describe 'edge error cases' do
      context 'with malformed log lines' do
        let(:malformed_log) do
          <<~LOG
            23/04/2019 15:34:22 - New match 11348965 has started
            This is a malformed line
            23/04/2019 15:36:04 - Roman killed Nick using M16
            Another bad line
            23/04/2019 15:39:22 - Match 11348965 has ended
          LOG
        end

        subject(:malformed_parser) { described_class.new(malformed_log) }

        it 'ignores malformed lines and continues parsing' do
          expect { malformed_parser.parse }.not_to raise_error
          expect(Match.count).to eq(1)
          expect(Kill.count).to eq(1)
        end
      end

      context 'with duplicate match IDs' do
        it 'does not create duplicate matches' do
          parser.parse
          expect { parser.parse }.not_to change(Match, :count)
        end
      end
    end

    describe 'return value' do
      it 'returns Success result on successful parsing' do
        result = parser.parse
        expect(result).to be_success
        expect(result.value![:processed]).to be > 0
        expect(result.value!).not_to have_key(:errors)
      end

      context 'with empty content' do
        let(:empty_parser) { described_class.new('') }

        it 'returns Failure for empty content' do
          result = empty_parser.parse
          expect(result).to be_failure
          expect(result.failure).to eq(:empty_content)
        end
      end

      context 'with unknown events' do
        let(:mixed_log) do
          <<~LOG
            23/04/2019 15:34:22 - New match 11348965 has started
            23/04/2019 15:35:00 - Player joined the server
            23/04/2019 15:36:04 - Roman killed Nick using M16
            23/04/2019 15:39:22 - Match 11348965 has ended
          LOG
        end
        let(:mixed_parser) { described_class.new(mixed_log) }

        it 'returns Success with errors for unknown events' do
          result = mixed_parser.parse
          expect(result).to be_success
          expect(result.value![:processed]).to eq(4)
          expect(result.value![:errors]).to be_present
          expect(result.value![:errors].first).to include("Unknown event format")
        end
      end
    end
  end
end
