class MatchController < ApplicationController
  before do
    requires_login!
  end
  before '/seasons/:season_id' do |season_id|
    @season = Season[id: season_id]
    halt 404, "Season #{season_id} couldn't be found" if @seasons.nil?
  end
  get '/seasons' do
    seasons = []
    if params[:owned].nil?
      seasons = Season.all
    else
      seasons = Season[owner_id: principal.id]
    end
    json seasons: seasons
  end
  post '/seasons' do
    season_param_presence!
    new_season = Season.new params[:season]
    new_season.owner_id = principal.id
    halt 400, json(errors: new_season.errors) unless new_season.valid?
    new_season.save
    status 201
    logger.info "Season #{new_season.id} successfully created"
    json id: new_season.id
  end
  delete '/seasons/:season_id' do |season_id|
  end
  helpers do
    def season_param_presence!
      halt 400, "No season object found in request payload" if params[:season].nil?
    end
  end
end
