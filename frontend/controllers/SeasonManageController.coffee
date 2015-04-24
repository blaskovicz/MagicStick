angular.module("MagicStick.controllers").controller "SeasonManageController", [
  "$scope"
  "User"
  "$http"
  "season"
  "toastr"
  ($scope, User, $http, season, toastr) ->
    $scope.season = season
    $scope.seasonOwner = ->
      season?.owner?.username is User.username
    $scope.createSeasonGrouping = (groupingName) ->
      $http.post("/api/match/seasons/#{season.id}/match-groups",
        { name: groupingName }
      ).success (newGroup) ->
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
          group = _.find(
            $scope.season.season_match_groups,
            ((item) -> item.id is newMatchSlug.season_match_group_id)
          )
          group.matches.push newMatch if group?
        .error (data) ->
          toastr.error "Couldn't create match"
          $scope.newMatchError = data?.errors
    $scope.deleteMatch = ->
]
