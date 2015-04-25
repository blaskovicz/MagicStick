angular.module("MagicStick.controllers").controller "SeasonManageController", [
  "$scope"
  "User"
  "$http"
  "season"
  "toastr"
  ($scope, User, $http, season, toastr) ->
    $scope.season = season
    $scope.isCurrentUser = (username) -> username is User.username
    $scope.seasonOwner = ->
      season?.owner?.username is User.username
    $scope.createSeasonGrouping = (groupingName) ->
      $http.post("/api/match/seasons/#{season.id}/match-groups", {
        name: groupingName
      }).success (newGroup) ->
          toastr.success "Grouping successfully created"
          season.season_match_groups.push newGroup
          $scope.newGroupingNameError = null
          $scope.newGroupingName = null
        .error (data) ->
          $scope.newGroupingNameError =
            data?.errors?.name ? \
            data?.errors["[:season_id, :name]"] ? \
            ["is invalid"]
    $scope.removeSeasonGrouping = (group) ->
      $http.delete("/api/match/seasons/#{season.id}/match-groups/#{group.id}")
        .success ->
          toastr.success "Successfully deleted match group"
          _.remove season.season_match_groups,
            (nextGroup) -> nextGroup.id is group.id
        .error (reason) ->
          toastr.error "Failed to remove season match grouping" +
            reason?.error ? ""
    $scope.addSeasonMember = (newMember) ->
      $http.put("/api/match/seasons/#{season.id}/members/#{newMember.id}")
        .success ->
          toastr.success "User added to season"
          season.members.push newMember
          $scope.newMember = null
        .error (reason) ->
          toastr.error "Failed to add #{newMember.username} to season" +
           reason?.error ? ""
    $scope.findMembersMatching = (text) ->
      $http.get("/api/auth/users", {
        params:
          limitted: true
          matching: text
      }).then (response) -> response.data.users
    $scope.removeSeasonMember = (member) ->
      $http.delete("/api/match/seasons/#{season.id}/members/#{member.id}")
        .success ->
          toastr.success "User removed from season"
          _.remove season.members, (nextMember) -> nextMember.id is member.id
        .error (reason) ->
          toastr.error "Failed to remove user #{member.username} from season" +
            reason?.error ? ""
    $scope.newMatch =
      scheduled_for: new Date()
    $scope.newMatchError = null
    $scope.createMatch = ->
      return unless $scope.newMatch.season_match_group_id?
      newMatchSlug = angular.copy $scope.newMatch
      $http.post("/api/match/seasons/#{season.id}" + \
        "/match-groups/#{newMatchSlug.season_match_group_id}/matches", {
          match: newMatchSlug
      }).success (newMatch) ->
          toastr.success "Match #{newMatch.id} successfully created"
          group = findGroup newMatchSlug.season_match_group_id
          group.matches ?= []
          group.matches.push newMatch if group?
        .error (data) ->
          toastr.error "Couldn't create match"
          $scope.newMatchError = data?.errors
    $scope.deleteMatch = (groupId, matchId) ->
      $http.delete(matchPath(groupId, matchId))
        .success ->
          toastr.success "Match #{matchId} successfully deleted"
          group = findGroup groupId
          return unless group?
          _.remove group.matches, ((item) -> item.id is matchId)
        .error (data) ->
          toastr.error "Couldn't delete match: #{data}"
    $scope.addNextMatchMember = (nextMatchMember, groupId, matchId) ->
      $http.put("#{matchPath(groupId, matchId)}/members/#{nextMatchMember.id}")
        .success ->
          toastr.success "Successfully added user to match"
          refreshMatchMembers groupId, matchId
        .error (data) ->
          toastr.error "Couldn't add user to match: #{data.errors ? data}"
    $scope.removeMatchMember = (memberId, groupId, matchId) ->
      $http.delete("#{matchPath(groupId, matchId)}/members/#{memberId}")
        .success ->
          toastr.success "Successfully removed user from match"
          refreshMatchMembers groupId, matchId
        .error (data) ->
          toastr.error \
            "Couldn't remove member from match: #{data.errors ? data}"
    $scope.isMatchMember = (match) ->
      return false unless match?.user_season_match?.length > 0
      member = _.find(
        match.user_season_match,
        ((item) -> item.user_season.user.username is User.username)
      )
      member?
    $scope.updateMatchStatus = (groupId, matchId, memberId, newStatus) ->
      $http.put("#{matchPath(groupId, matchId)}/members/#{memberId}/status", {
        status: newStatus
      }).success ->
          toastr.success "Successfully updated match member status"
          refreshMatchMembers groupId, matchId
        .error (data) ->
          toastr.error \
            "Couldn't update member match status: #{data.errors ? data}"
    # reload the members of the match from the api since the json
    # format is non-trivial
    refreshMatchMembers = (groupId, matchId) ->
      match = findMatch groupId, matchId
      return unless match?
      $http.get(matchPath(groupId, matchId))
        .success (matchData) ->
          match.user_season_match = matchData.user_season_match
    findMatch = (groupId, matchId) ->
      return unless matchId? and groupId?
      group = findGroup groupId
      return unless group?
      _.find(group.matches, ((item) -> item.id is matchId))
    findGroup = (groupId) ->
      _.find(
        season.season_match_groups,
        ((item) -> item.id is groupId)
      )
    matchPath = (groupId, matchId) ->
      "/api/match/seasons/#{season.id}"+ \
      "/match-groups/#{groupId}/matches/#{matchId}"
]
