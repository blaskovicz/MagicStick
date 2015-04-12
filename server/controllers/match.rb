class MatchController < ApplicationController
  before do
    requires_login!
  end
  before %r{^/seasons/(?<season_id>[^/]+)} do
    @season = Season[id: params[:season_id]]
    json_halt 404, "Season #{params[:season_id]} couldn't be found" if @season.nil?
  end
  get '/seasons' do
    if params[:owned].nil?
      seasons = Season
    else
      seasons = Season.filter(owner_id: principal.id)
    end
    seasons.to_json(root: true, include: {:owner => {:only => [:username]}})
  end
  get '/seasons/:season_id' do
    @season.to_json(include: {
      :season_match_groups => {},
      :owner => {:only => [:username]},
      :members => {:only => [:username, :id]}
    })
  end
  post '/seasons/:season_id/match-groups' do
    halt_403 unless @season.owner == principal
    match_group = SeasonMatchGroup.new
    match_group.name = params[:name]
    match_group.season = @season
    json_halt 400, match_group.errors unless match_group.valid?
    match_group.save
    status 201
    logger.info "SeasonMatchGroup #{match_group.id} successfully created"
    match_group.to_json
  end
  delete '/seasons/:season_id/match-groups/:match_group_id' do |season_id, match_group_id|
    halt_403 unless @season.owner == principal
    match_group = SeasonMatchGroup.where(id: match_group_id, season_id: season_id).first
    json_halt 404, "No match group with id #{match_group_id} found" if match_group.nil?
    match_group.delete
    status 204
  end
  put '/seasons/:season_id/members/:member_id' do |season_id, member_id|
    # TODO
    # cases: (owner vs not), (invite_only vs not), (invited vs not), (auto join vs not), (archived vs not) 
    halt_403 unless @season.owner == principal
    target_member = find_member! member_id
    @season.add_member target_member
    status 204
  end
  delete '/seasons/:season_id/members/:member_id' do |season_id, member_id|
    halt_403 unless @season.owner == principal
    target_member = find_member! member_id
    @season.remove_member target_member
    status 204
  end
  post '/seasons' do
    season_param_presence!
    new_season = Season.new params[:season]
    new_season.owner_id = principal.id
    json_halt 400, new_season.errors unless new_season.valid?
    new_season.save
    status 201
    logger.info "Season #{new_season.id} successfully created"
    json id: new_season.id
  end
  delete '/seasons/:season_id' do |season_id|
  end
  helpers do
    def find_member!(id)
      user = User[id: id]
      json_halt 404, "No member with id #{id} found" if user.nil?
      user
    end
    def season_param_presence!
      json_halt 400, "No season object found in request payload" if params[:season].nil?
    end
  end
end
