angular.module("MagicStick.controllers").controller "SeasonDashController", [
  "$scope"
  "$http"
  "User"
  "toastr"
  ($scope, $http, User, toastr) ->
    $scope.newSeason = {}
    $scope.newSeasonError = {}
    $scope.user = User
    $scope.loadSeasons = ->
      $http.get("/api/match/seasons")
        .success (data) ->
          $scope.seasons = data.seasons
        .error (data) ->
          toastr.error "Failed to load seasons: #{data}"
    $scope.createSeason = ->
      $http.post("/api/match/seasons", season: $scope.newSeason)
        .success (data) ->
          toastr.success "Created new season"
          $scope.newSeason = {}
          $scope.newSeasonError = {}
        .error (data) ->
          toastr.error "Failed to create season"
          $scope.newSeasonError = data.errors
    $scope.loadSeasons()
]
