require_relative '../spec_helper'
require_relative '../../models/match'
require_relative '../../helpers/slack'
require_relative '../../helpers/link'

describe 'Match' do
  include Slack
  include Link
  def password
    'test-password'
  end

  before(:all) do
    @user = User.new(
      username: 'matchm_spec_tests_user',
      password: password,
      email: 'matchm_spec_tests_user@magic-stick.herokuapp.com',
      name: 'matchm specuser'
    )
    raise 'failed to save user' unless @user.save
    @user2 = User.new(
      username: 'matchm_spec_tests_user2',
      password: password,
      email: 'matchm_spec_tests_user2@magic-stick.herokuapp.com',
      name: 'matchm specuser2'
    )
    raise 'failed to save user2' unless @user2.save
    @season = Season.new(
      name: 'matchm_spec_tests',
      description: 'sweet season',
      invite_only: true,
      owner: @user,
      starts: Time.now,
      ends: (Time.now + 5_000)
    )
    raise 'failed to save season' unless @season.save
    @smg = SeasonMatchGroup.new(season: @season, name: 'another-groupm')
    raise 'failed to save smg' unless @smg.save
    @match = Match.new(season_match_group: @smg, best_of: 3, scheduled_for: Time.now + 1_100, description: 'somethin')
    raise 'failed to save match' unless @match.save
    @season.add_member @user
    @season.add_member @user2
  end

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

  it 'should generate a valid fqtitle' do
    expect(@match.title).to eq('matchm_spec_tests > another-groupm > somethin')
    expect(slack_escape(@match.title)).to eq('matchm_spec_tests &gt; another-groupm &gt; somethin')
  end

  it 'should check match membership' do
    expect(@match.member?(@user)).to be(false)
    expect(@match.member?(@user2)).to be(false)
  end

  it 'should allow user addition to match' do
    expect(@match.member?(@user)).to be(false)
    expect(@match.member?(@user2)).to be(false)
    expect(@match.find_member(@user.id)).to be_nil
    expect(@match.find_member(@user2.id)).to be_nil

    @match.add_member(@user)
    @match.reload
    expect(@match.member?(@user)).to be(true)
    expect(@match.member?(@user2)).to be(false)
    expect(@match.find_member(@user.id)).not_to be_nil
    expect(@match.find_member(@user2.id)).to be_nil

    @match.add_member(@user2)
    @match.reload
    expect(@match.member?(@user)).to be(true)
    expect(@match.member?(@user2)).to be(true)
    expect(@match.find_member(@user.id)).not_to be_nil
    expect(@match.find_member(@user2.id)).not_to be_nil
    expect { @match.find_member(@user2.id).save }.not_to raise_error
  end
end
