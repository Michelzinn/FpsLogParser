require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:match_players).dependent(:destroy) }
    it { should have_many(:matches).through(:match_players) }
    it { should have_many(:kills_as_killer).class_name('Kill').with_foreign_key('killer_id').dependent(:destroy) }
    it { should have_many(:kills_as_victim).class_name('Kill').with_foreign_key('victim_id').dependent(:destroy) }
  end

  describe '#total_kills' do
    let(:player) { create(:player) }
    let(:match1) { create(:match) }
    let(:match2) { create(:match) }

    before do
      create(:match_player, player: player, match: match1, kills_count: 5)
      create(:match_player, player: player, match: match2, kills_count: 3)
    end

    it 'returns sum of all kills' do
      expect(player.total_kills).to eq(8)
    end
  end

  describe '#total_deaths' do
    let(:player) { create(:player) }
    let(:match1) { create(:match) }
    let(:match2) { create(:match) }

    before do
      create(:match_player, player: player, match: match1, deaths_count: 2)
      create(:match_player, player: player, match: match2, deaths_count: 4)
    end

    it 'returns sum of all deaths' do
      expect(player.total_deaths).to eq(6)
    end
  end

  describe '#kd_ratio' do
    let(:player) { create(:player) }
    let(:match) { create(:match) }

    context 'when player has deaths' do
      before do
        create(:match_player, player: player, match: match, kills_count: 10, deaths_count: 5)
      end

      it 'returns kills divided by deaths' do
        expect(player.kd_ratio).to eq(2.0)
      end
    end

    context 'when player has no deaths' do
      before do
        create(:match_player, player: player, match: match, kills_count: 10, deaths_count: 0)
      end

      it 'returns kills count' do
        expect(player.kd_ratio).to eq(10.0)
      end
    end

    context 'when player has no kills or deaths' do
      it 'returns 0.0 when no deaths' do
        expect(player.kd_ratio).to eq(0.0)
      end
    end
  end

end