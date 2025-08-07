require 'rails_helper'

RSpec.describe Match, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:match_id) }
    it { should validate_presence_of(:started_at) }
    it { should validate_uniqueness_of(:match_id) }
  end

  describe 'associations' do
    it { should have_many(:match_players).dependent(:destroy) }
    it { should have_many(:players).through(:match_players) }
    it { should have_many(:kills).dependent(:destroy) }
  end

  describe 'scopes' do
    describe '.ordered' do
      let!(:match1) { create(:match, started_at: 2.days.ago) }
      let!(:match2) { create(:match, started_at: 1.day.ago) }
      let!(:match3) { create(:match, started_at: 3.days.ago) }

      it 'returns matches ordered by started_at desc' do
        expect(Match.ordered).to eq([match2, match1, match3])
      end
    end
  end

  describe '#duration' do
    context 'when match has ended' do
      let(:match) { create(:match, started_at: 1.hour.ago, ended_at: Time.current) }

      it 'returns the duration in seconds' do
        expect(match.duration).to be_within(1).of(3600)
      end
    end

    context 'when match has not ended' do
      let(:match) { create(:match, ended_at: nil) }

      it 'returns nil' do
        expect(match.duration).to be_nil
      end
    end
  end

  describe '#winner' do
    let(:match) { create(:match) }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }

    before do
      create(:match_player, match: match, player: player1, kills_count: 5, deaths_count: 2)
      create(:match_player, match: match, player: player2, kills_count: 3, deaths_count: 4)
      create(:match_player, match: match, player: player3, kills_count: 7, deaths_count: 1)
    end

    it 'returns the player with most kills' do
      expect(match.winner).to eq(player3)
    end
  end

  describe '#active?' do
    context 'when match has not ended' do
      let(:match) { create(:match, ended_at: nil) }

      it 'returns true' do
        expect(match.active?).to be true
      end
    end

    context 'when match has ended' do
      let(:match) { create(:match, ended_at: Time.current) }

      it 'returns false' do
        expect(match.active?).to be false
      end
    end
  end
end