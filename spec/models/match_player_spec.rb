require 'rails_helper'

RSpec.describe MatchPlayer, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:match_id) }
    it { should validate_presence_of(:player_id) }
    it { should validate_numericality_of(:kills_count).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:deaths_count).is_greater_than_or_equal_to(0) }
    
    describe 'uniqueness' do
      let(:match) { create(:match) }
      let(:player) { create(:player) }
      let!(:match_player) { create(:match_player, match: match, player: player) }

      it 'validates uniqueness of player per match' do
        duplicate = build(:match_player, match: match, player: player)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:player_id]).to include("has already been taken")
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:match) }
    it { should belong_to(:player) }
  end

  describe '#score' do
    let(:match_player) { build(:match_player, kills_count: 10, deaths_count: 5) }

    it 'returns kills minus deaths' do
      expect(match_player.score).to eq(5)
    end
  end

  describe '#kd_ratio' do
    context 'when player has deaths' do
      let(:match_player) { build(:match_player, kills_count: 10, deaths_count: 5) }

      it 'returns kills divided by deaths' do
        expect(match_player.kd_ratio).to eq(2.0)
      end
    end

    context 'when player has no deaths' do
      let(:match_player) { build(:match_player, kills_count: 10, deaths_count: 0) }

      it 'returns kills count' do
        expect(match_player.kd_ratio).to eq(10.0)
      end
    end

    context 'when player has no kills or deaths' do
      let(:match_player) { build(:match_player, kills_count: 0, deaths_count: 0) }

      it 'returns 0' do
        expect(match_player.kd_ratio).to eq(0.0)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      let(:match_player) { build(:match_player, kills_count: nil, deaths_count: nil) }

      it 'sets default values for counts' do
        match_player.valid?
        expect(match_player.kills_count).to eq(0)
        expect(match_player.deaths_count).to eq(0)
      end
    end
  end
end