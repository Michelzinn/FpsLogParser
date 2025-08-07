require 'rails_helper'

RSpec.describe Kill, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:match_id) }
    it { should validate_presence_of(:victim_id) }
    it { should validate_presence_of(:weapon) }
    it { should validate_presence_of(:occurred_at) }
  end

  describe 'associations' do
    it { should belong_to(:match) }
    it { should belong_to(:killer).class_name('Player').optional }
    it { should belong_to(:victim).class_name('Player') }
  end

  describe 'scopes' do
    describe '.by_player' do
      let(:player) { create(:player) }
      let(:other_player) { create(:player) }
      let(:match) { create(:match) }
      let!(:kill1) { create(:kill, match: match, killer: player, victim: other_player) }
      let!(:kill2) { create(:kill, match: match, killer: other_player, victim: player) }
      let!(:kill3) { create(:kill, match: match, killer: nil, victim: player, world_kill: true) }

      it 'returns kills by specific player' do
        expect(Kill.by_player(player)).to contain_exactly(kill1)
      end
    end

    describe '.world_kills' do
      let(:player) { create(:player) }
      let(:match) { create(:match) }
      let!(:regular_kill) { create(:kill, match: match, killer: player) }
      let!(:world_kill) { create(:kill, match: match, killer: nil, world_kill: true) }

      it 'returns only world kills' do
        expect(Kill.world_kills).to contain_exactly(world_kill)
      end
    end
  end

  describe '#world_kill?' do
    context 'when killer is nil' do
      let(:kill) { build(:kill, killer: nil, world_kill: true) }

      it 'returns true' do
        expect(kill.world_kill?).to be true
      end
    end

    context 'when killer is present' do
      let(:kill) { build(:kill, killer: create(:player)) }

      it 'returns false' do
        expect(kill.world_kill?).to be false
      end
    end
  end
end