class MatchController < ApplicationController
  before do
    requires_login!
  end
  before %r{^/seasons/(?<season_id>[^/]+)} do
    @season = Season[id: params[:season_id]]
    json_halt 404, "Season #{params[:season_id]} couldn't be found" if @season.nil?
  end
  before %r{/seasons/(?<season_id>[^/]+)/match-groups/(?<match_group_id>[^/]+)/matches/(?<match_id>[^/]+)} do
    # there has to be an easier way to do this? TODO
    @match = Match
      .where(id: params[:match_id])
      .where(season_match_group_id: SeasonMatchGroup
        .where(id: params[:match_group_id])
        .where(season_id: Season
          .where(id: params[:season_id])
          .select(:id)
        ).select(:id)
      ).first
    json_halt 404, "No match found (season #{params[:season_id]}, match group #{params[:match_group_id]}, match #{params[:match_id]})" if @match.nil?   
  end
  before %r{/.+/members/(?<user_id>[^/]+)} do
    @member = User[id: params[:user_id]]
    json_halt 404, "User #{params[:user_id]} not found" if @member.nil?
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
      :season_match_groups => {include: {:matches => {include: []}}},
      :owner => {:only => [:username]},
      :members => {:only => [:username, :id]}
    })
  end
  put '/seasons/:season_id/match-groups/:group_id/matches/:match_id/members/:member_id' do |season_id, group_id, match_id, member_id|
    requires_season_owner!
    requires_season_membership! season_id, member_id
    $DB.transaction do
      user_season = $DB[:users_seasons].where(user_id: member_id, season_id: season_id).first
      if $DB[:users_seasons_matches].where(user_season_id: user_season[:id], match_id: match_id).first.nil?
        $DB[:users_seasons_matches].insert(user_season_id: user_season[:id], match_id: match_id)
      end
    end
    status 204
  end
  delete '/seasons/:season_id/match-groups/:group_id/matches/:match_id/members/:member_id' do |season_id, group_id, match_id, member_id|
    requires_season_owner!
    requires_season_membership! season_id, member_id
    $DB.transaction do
      user_season = $DB[:users_seasons].where(user_id: member_id, season_id: season_id).first
      $DB[:users_seasons_matches].where(user_season_id: user_season[:id], match_id: match_id).delete
    end
    status 204
  end
  put '/seasons/:season_id/match-groups/:group_id/matches/:match_id/status' do |season_id, group_id, match_id|
    requires_match_privs!
  end
  post '/seasons/:season_id/match-groups/:group_id/matches' do |season_id, group_id|
    requires_season_owner!
    json_halt 400, "Match parameter missing from request payload" if params[:match].nil?
    match_group = SeasonMatchGroup.where(season_id: season_id, id: group_id).first
    json_halt 404, "Match group #{group_id} not found in season #{season_id}" if match_group.nil?
    new_match = Match.new params[:match]
    new_match.season_match_group = match_group
    json_halt 400, new_match.errors unless new_match.valid?
    new_match.save
    status 201
    logger.info "Match #{new_match.id} successfully created"
    new_match.to_json
  end
  get '/seasons/:season_id/match-groups/:group_id/matches/:match_id' do
    requires_login!
    # this is required since the model has extra fields that cant be serialized  into a Match row
    @match.to_json(:only => [:id, :created_at, :scheduled_for, :completed, :description])
  end
  delete '/seasons/:season_id/match-groups/:group_id/matches/:match_id' do |season_id, group_id, match_id|
    requires_season_owner!
    @match.delete
    status 204
  end
  post '/seasons/:season_id/match-groups' do
    requires_season_owner!
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
    requires_season_owner!
    match_group = SeasonMatchGroup.where(id: match_group_id, season_id: season_id).first
    json_halt 404, "No match group with id #{match_group_id} found" if match_group.nil?
    match_group.delete
    status 204
  end
  put '/seasons/:season_id/members/:member_id' do |season_id, member_id|
    # TODO
    # cases: (owner vs not), (invite_only vs not), (invited vs not), (auto join vs not), (archived vs not) 
    requires_season_owner!
    @season.add_member @member
    status 204
  end
  delete '/seasons/:season_id/members/:member_id' do |season_id, member_id|
    requires_season_owner!
    @season.remove_member @member
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
    requires_season_owner!
    @season.delete
    status 204
  end
  helpers do
    def requires_season_owner!
      halt_403 unless @season.owner == principal
    end
    def season_param_presence!
      json_halt 400, "No season object found in request payload" if params[:season].nil?
    end
    def has_season_membership(user_id, season_id)
      not $DB[:users_seasons].where(user_id: user_id, season_id: season_id).first.nil?
    end
    def requires_season_membership!(user_id, season_id)
      json_halt 400, "User #{user_id} isn't a member of season #{season_id}" unless has_season_membership(user_id, season_id)
    end
  end
end
