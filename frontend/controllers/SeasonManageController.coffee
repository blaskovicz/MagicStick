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
      $http.post("/api/match/seasons/#{season.id}/match-groups", { name: groupingName })
        .success (newGroup) ->
          toastr.success "Grouping successfully created"
        .error ->
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
]
