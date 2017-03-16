require_relative '../spec_helper'
require_relative '../../models/season'

describe 'Season' do
  context 'validations' do
    it 'should set and check reasonable defaults' do
      season = Season.new(allow_auto_join: true, invite_only: true)
      expect(season).not_to be_valid
      expect(season.errors).not_to be_empty
      expect(season.errors[:allow_auto_join]).not_to be_empty
      expect(season.errors[:invite_only]).not_to be_empty
    end

    it 'can be created once valid' do
      owner = User.first
      season = Season.new(
        name: 'test2',
        description: 'sweet season',
        invite_only: true,
        owner: owner,
        starts: Time.now,
        ends: (Time.now + 10_000)
      )
      expect(season.is_archived).to be_nil
      expect(season.allow_auto_join).to be_nil
      expect(season).to be_valid
      expect(season.save).not_to be_nil
      expect(season.allow_auto_join).to be(false)
      expect(season.is_archived).to be(false)
    end
  end
  context 'membership' do
    it 'allows being checked from a user' do
      season = Season.find(name: 'test2')
      expect(season.member?(season.owner)).to eq(false)
      expect(season.member?(season.owner.id)).to eq(false)
    end
    it 'allows being updated' do
      season = Season.find(name: 'test2')
      expect(season.add_member(season.owner)).not_to be_nil
      expect(season.member?(season.owner)).to eq(true)
      expect(season.member?(season.owner.id)).to eq(true)
    end
  end
end
