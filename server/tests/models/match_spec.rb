require_relative '../spec_helper'
require_relative '../../models/match'

describe 'Match' do
  context 'validations' do
    it 'should set and check reasonable defaults' do
      match = Match.new
      expect(match.best_of).to be_nil
      expect(match.valid?).to be(false)
      expect(match.errors[:best_of]).to be_nil
      expect(match.errors[:scheduled_for]).not_to be_nil
      expect(match.best_of).not_to be_nil
    end
  end
end
