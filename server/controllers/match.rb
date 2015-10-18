class MatchController < ApplicationController
  before do
    requires_login!
  end
  before %r{^/seasons/(?<season_id>[^/]+)} do
    @season = Season[id: params[:season_id]]
    json_halt 404, "Season #{params[:season_id]} couldn't be found" if @season.nil?
  end
  before %r{^/seasons/(?<season_id>[^/]+)/comments/(?<comment_id>[^/]+)} do
    @season_comment = @season.season_comments_dataset.where(id: params[:comment_id]).select_all(:seasons_comments).first
    json_halt 404, "Comment #{params[:comment_id]} couldn't be found in season #{params[:season_id]}" if @season_comment.nil?
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
      )
      .select_all(:matches) # this is required since the model has extra fields that cant be json-serialized into a Match row
      .first
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
    seasons.to_json(root: true, include: {:owner => {:only => User.public_attrs}})
  end
  get '/seasons/:season_id' do
    @season.to_json(include: {
      season_match_groups: {
        include: {
          matches: {
            include: {
              user_season_match: {
                include: {
                  user_season: {
                    include: {
                      user: {
                        only: User.public_attrs
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      :owner => {:only => User.public_attrs},
      :members => {:only => User.public_attrs}
    })
  end
  get '/seasons/:season_id/comments/:comment_id' do
    @season_comment.to_json(root: true, include: {
      user: {
        only: User.public_attrs
      }
    })
  end
  post '/seasons/:season_id/comments' do |season_id|
    comment = SeasonComment.new
    comment.user = principal
    comment.season = @season
    comment.comment = params[:comment]
    json_halt 400, comment.errors unless comment.valid?
    comment.save
    status 201
    slack_message(
      "\n*<#{link_to_user principal.username}|#{slack_escape principal.username}>* *commented* on *<#{link_to_season season_id}|#{slack_escape @season.name}>*\n>#{slack_escape comment.comment}"
    )
    comment.to_json(root: true, include: {
      user: {
        only: User.public_attrs
      }
    })
  end
  put '/seasons/:season_id/comments/:comment_id' do
    requires_seasoncomment_owner!
    @season_comment.comment = params[:comment]
    json_halt 400, @season_comment.errors unless @season_comment.valid?
    @season_comment.save
    status 200
    @season_comment.to_json(root: true, include: {
      user: {
        only: User.public_attrs
      }
    })
  end
  delete '/seasons/:season_id/comments/:comment_id' do
    halt_403 unless (
      (@season_comment.user == principal) || (@season.owner == principal)
    )
    @season_comment.hidden = true
    @season_comment.save
    status 204
  end
  get '/seasons/:season_id/comments' do
    @season.season_comments_dataset.order(:created_at).to_json(root: true, include: {
      user: {
        only: User.public_attrs
      }
    })
  end
  put '/seasons/:season_id/match-groups/:group_id/matches/:match_id/members/:member_id' do |season_id, group_id, match_id, member_id|
    requires_season_owner!
    requires_season_membership! season: season_id, member: member_id
    $DB.transaction do
      user_season = UserSeason.where(user_id: member_id, season_id: season_id).first
      user_season_match = UserSeasonMatch.new
      user_season_match.user_season = user_season
      user_season_match.match = @match
      if user_season_match.valid?
        user_season_match.save
      end
    end
    status 204
  end
  delete '/seasons/:season_id/match-groups/:group_id/matches/:match_id/members/:member_id' do |season_id, group_id, match_id, member_id|
    requires_season_owner!
    requires_season_membership! season: season_id, member: member_id
    $DB.transaction do
      user_season = UserSeason.where(user_id: member_id, season_id: season_id).first
      UserSeasonMatch.where(user_season: user_season, match: @match).delete
    end
    status 204
  end
  put '/seasons/:season_id/match-groups/:group_id/matches/:match_id/members/:member_id/status' do |season_id, group_id, match_id, member_id|
    requires_match_membership!
    user_season_match = UserSeasonMatch.where(user_season: UserSeason.where(user_id: member_id, season_id: season_id).first,  match: @match).first
    json_halt 404, "Member #{member_id} not found as part of match #{match_id}, group #{group_id}, season #{season_id}" if user_season_match.nil?
    attempt_save = false
    previous_state = user_season_match.clone
    if params.has_key? "status"
      attempt_save = true
      user_season_match.won = params[:status]
    end
    if params.has_key? "game_wins"
      attempt_save = true
      user_season_match.game_wins = params[:game_wins]
    end
    if attempt_save
      json_halt 400, user_season_match.errors unless user_season_match.valid?
      user_season_match.save
      logger.info(
        "#{principal.username} just updated the status of season-#{season_id}/group-#{group_id}/match-#{match_id}/user-#{member_id}" +
        "from #{previous_state.inspect} to #{user_season_match.inspect}"
      )
      def format_win_state(state)
        if state
          "_WIN_ :thumbsup:"
        else
          "_LOSS_ :thumbsdown:"
        end
      end
      # we want to say "[Principal] just updated the status of [Season Name] >> [Group Name] > [Match Name] >> [Member Name]
      # only report overall match reporting to slack
      if previous_state.won != user_season_match.won
        slack_message(
          "*<#{link_to_user principal.username}|#{slack_escape principal.username}>* just *updated* " +
          (@member.id == principal.id ? "their own *status* " : "the *status* of *<#{link_to_user @member.username}|#{slack_escape @member.username}>* ") +
          "in match *<#{link_to_season season_id}|#{slack_escape @season.name}>* &gt; " +
          "#{slack_escape SeasonMatchGroup.where(season_id: season_id, id: group_id).first.name} &gt; " +
          "#{slack_escape @match.description}\n" +
          (previous_state.won.nil? ? "" : "from #{format_win_state previous_state.won}") + " to #{format_win_state user_season_match.won}"
        )
      end
      #TODO should we also mark other people as finished here?
    end
    status 204
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
    # this output should match what's returned by /seasons/:season except at a lower-level of nesting.
    #
    # ideally, since we're treating these tables as sub-resources, we'd want to be able to have
    # each and every route in between defined for all actions (get/put/post, etc) dynamically
    # so that we dont have to manually create them all TODO
    @match.to_json(
      include: {
        user_season_match: {
          include: {
            user_season: {
              include: {
                user: {
                  only: User.public_attrs
                }
              }
            }
          }
        }
      }
    )
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
    if @season.members_dataset.where(users__id: member_id).first.nil?
      @season.add_member @member
    end
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
    def requires_seasoncomment_owner!
      halt_403 unless (
        @season_comment.user == principal
      )
    end
    def requires_match_membership!
      halt_403 unless (
        @season.owner == principal ||
        @match.user_season_match.map{|m| m.user.id}.include?(principal.id) #TODO is there a more correct way to do this?
      )
    end
    def requires_season_owner!
      halt_403 unless @season.owner == principal
    end
    def season_param_presence!
      json_halt 400, "No season object found in request payload" if params[:season].nil?
    end
    def requires_season_membership!(season:, member:)
      json_halt 400, "User #{member} isn't a member of season #{season}" if UserSeason.where(user_id: member, season_id: season).first.nil?
    end
  end
end
