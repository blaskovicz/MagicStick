require_relative '../spec_helper'
require_relative '../../controllers/match'

describe 'Match' do
  def app
    MatchController
  end

  def password
    'test-password'
  end

  before(:all) do
    @user = User.new(
      username: 'match_spec_tests_user',
      password: password,
      email: 'match_spec_tests_user@magic-stick.herokuapp.com',
      name: 'match specuser'
    )
    raise 'failed to save user' unless @user.save
    @user2 = User.new(
      username: 'match_spec_tests_user2',
      password: password,
      email: 'match_spec_tests_user2@magic-stick.herokuapp.com',
      name: 'match specuser2'
    )
    raise 'failed to save user2' unless @user2.save
    @season = Season.new(
      name: 'match_spec_tests',
      description: 'sweet season',
      invite_only: true,
      owner: @user,
      starts: Time.now,
      ends: (Time.now + 5_000)
    )
    raise 'failed to save season' unless @season.save
    @smg = SeasonMatchGroup.new(season: @season, name: 'another-group')
    raise 'failed to save smg' unless @smg.save
    @match = Match.new(season_match_group: @smg, best_of: 3, scheduled_for: Time.now + 3_124, description: 'sweetness')
    raise 'failed to save match' unless @match.save
  end

  before(:each) do
    clear_deliveries
    expect(email_deliveries.count).to eq(0)
  end

  it 'should allow season creation' do
    authorize @user.username, password
    post '/seasons', season: {
      starts: Time.now,
      ends: Time.now + 5_000,
      description: 'test season',
      invite_only: true,
      name: 'match spec test season'
    }
    expect(last_response.status).to eq(201)
    season = JSON.parse(last_response.body)
    expect(season).to have_key('id')
    expect(Season.find(id: season['id'])).not_to be_nil
  end

  it 'should allow adding a user to a season' do
    authorize @user.username, password
    expect(@season.member?(@user2)).to eq(false)
    put "/seasons/#{@season.id}/members/#{@user2.id}"
    expect(@season.member?(@user2)).to eq(true)
    expect(last_response.status).to eq(204)
    expect(email_deliveries.count).to eq(2)
    expect(deliveries).to include(@user.email, @user2.email)
  end

  it 'should allow removing a user from a season' do
    authorize @user.username, password
    expect(@season.member?(@user2)).to eq(true)
    delete "/seasons/#{@season.id}/members/#{@user2.id}"
    expect(@season.member?(@user2)).to eq(false)
    expect(last_response.status).to eq(204)
    expect(email_deliveries.count).to eq(2)
    expect(deliveries).to include(@season.owner.email, @user2.email)
  end

  it 'should allow creating and deleting match groups' do
    authorize @user.username, password
    post "/seasons/#{@season.id}/match-groups", name: 'fancy-group'
    expect(last_response.status).to eq(201)
    smg = JSON.parse(last_response.body)
    expect(smg).to have_key('id')
    expect(@season.season_match_groups.last.name).to eq('fancy-group')

    delete "/seasons/#{@season.id}/match-groups/#{smg['id']}"
    expect(last_response.status).to eq(204)
    @season.reload
    expect(@season.season_match_groups.last.name).not_to eq('fancy-group')
  end

  it 'should allow creating and deleting matches' do
    authorize @user.username, password
    post "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches", match: {
      best_of: 3,
      scheduled_for: Time.now + 1_000,
      description: 'new match'
    }
    expect(last_response.status).to eq(201)
    match = JSON.parse(last_response.body)
    expect(match).to have_key('id')
    expect(@smg.matches.last.id).to eq(match['id'])

    delete "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{match['id']}"
    expect(last_response.status).to eq(204)
    @smg.reload
    expect(@smg.matches.last.id).not_to eq(match['id'])
  end

  it 'should allow adding and removing a user from a match' do
    authorize @user.username, password
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}"
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body).to have_key('errors')
    expect(body['errors']).to eq("User #{@user2.id} isn't a member of season #{@season.id}")

    @season.add_member @user2
    clear_deliveries
    expect(@match.member?(@user2)).to eq(false)
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}"
    expect(last_response.status).to eq(204)
    @match.reload
    expect(@match.user_season_match.last.user.id).to eq(@user2.id)
    expect(@match.member?(@user2)).to eq(true)
    expect(email_deliveries.count).to eq(1)
    expect(deliveries).to include(@user2.email)

    # make sure we don't re-email
    clear_deliveries
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}"
    @match.reload
    expect(last_response.status).to eq(204)
    expect(@match.member?(@user2)).to eq(true)
    expect(email_deliveries.count).to eq(0)

    clear_deliveries
    delete "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}"
    expect(last_response.status).to eq(204)
    @match.reload
    expect(@match.user_season_match.last).to be_nil
    expect(@match.member?(@user2)).to eq(false)
    expect(email_deliveries.count).to eq(1)
    expect(deliveries).to include(@user2.email)

    # make sure we don't re-email
    clear_deliveries
    delete "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}"
    @match.reload
    expect(last_response.status).to eq(204)
    expect(@match.member?(@user2)).to eq(false)
    expect(email_deliveries.count).to eq(0)
  end
end
