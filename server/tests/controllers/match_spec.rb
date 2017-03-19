require_relative '../spec_helper'
require_relative '../../controllers/match'

describe 'Match' do
  def app
    MatchController
  end

  def password
    'test-password'
  end

  attr_reader :slack_double

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
    @user3 = User.new(
      username: 'match_spec_tests_user3',
      password: password,
      email: 'match_spec_tests_user3@magic-stick.herokuapp.com',
      name: 'match specuser3'
    )
    raise 'failed to save user3' unless @user3.save
    @user4 = User.new(
      username: 'match_spec_tests_user4',
      password: password,
      email: 'match_spec_tests_user4@magic-stick.herokuapp.com',
      name: 'match specuser4'
    )
    raise 'failed to save user4' unless @user4.save
    @season = Season.new(
      name: 'match_spec_tests',
      description: 'sweet season',
      invite_only: true,
      owner: @user,
      starts: Time.now,
      ends: (Time.now + 5_000)
    )
    raise 'failed to save season' unless @season.save
    @season.add_member @user3
    @season.add_member @user4
    @smg = SeasonMatchGroup.new(season: @season, name: 'another-group')
    raise 'failed to save smg' unless @smg.save
    @match = Match.new(season_match_group: @smg, best_of: 3, scheduled_for: Time.now + 3_124, description: 'sweetness')
    raise 'failed to save match' unless @match.save
    expect(@match.member?(@user3)).to eq(false)
    @match.add_member @user3
    expect(@match.member?(@user3)).to eq(true)
    expect(@match.member?(@user4)).to eq(false)
    @match.add_member @user4
    expect(@match.member?(@user4)).to eq(true)
  end

  before(:each) do
    clear_deliveries
    expect(email_deliveries.count).to eq(0)
    @slack_double = double('slack_double')
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

  it 'should allow reporting match status' do
    authorize @user3.username, password

    # dne member of match
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user2.id}/status"
    expect(last_response.status).to eq(404)
    expect(last_response_json['errors']).to eq("Member #{@user2.id} not found as part of match #{@match.id}, group #{@smg.id}, season #{@season.id}")

    # good member, bad request body
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user3.id}/status"
    expect(last_response.status).to eq(400)
    expect(last_response_json['errors']).to eq('game_wins or status keys must be specified')

    # now make real requests, but first verify state and mock notifier
    clear_deliveries
    allow(Slack::Notifier).to receive(:new).and_return(slack_double)
    allow(slack_double).to receive(:escape).and_return('escaped')
    allow(slack_double).to receive(:ping).and_return(nil)
    usm3 = @match.find_member(@user3)
    usm4 = @match.find_member(@user4)
    expect(usm3.won).to be_nil
    expect(usm4.won).to be_nil
    expect(usm3.game_wins).to eq(0)
    expect(usm4.game_wins).to eq(0)

    # good member, good request body
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user3.id}/status", status: true, game_wins: 2
    expect(last_response.status).to eq(204)
    usm3.reload
    usm4.reload
    expect(usm3.won).to eq(true)
    expect(usm4.won).to be_nil
    expect(usm3.game_wins).to eq(2)
    expect(usm4.game_wins).to eq(0)
    expect(delivery_count).to eq(2)
    expect(deliveries).to include(@user3.email, @user4.email)

    # good member2, good request body
    clear_deliveries
    put "/seasons/#{@season.id}/match-groups/#{@smg.id}/matches/#{@match.id}/members/#{@user4.id}/status", status: false, game_wins: 1
    expect(last_response.status).to eq(204)
    usm3.reload
    usm4.reload
    expect(usm3.won).to eq(true)
    expect(usm4.won).to eq(false)
    expect(usm3.game_wins).to eq(2)
    expect(usm4.game_wins).to eq(1)
    expect(delivery_count).to eq(2)
    expect(deliveries).to include(@user3.email, @user4.email)

    # TODO: add a check for reporting game_wins > best_of
  end
end
