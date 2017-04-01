angular.module("MagicStick.controllers").controller "SeasonDashController", [
  "$scope"
  "$http"
  "User"
  "toastr"
  "$location"
  ($scope, $http, User, toastr, $location) ->
    $scope.newSeason =
      name: ""
      description: ""
      starts: moment().toDate()
      ends: moment().add(1, 'months').toDate()
      allow_auto_join: true
      invite_only: false
    savedSeason = angular.copy $scope.newSeason
    $scope.newSeasonError = {}
    $scope.user = User
    $scope.assertJoinType = (type) ->
      otherType =
        if type is 'invite_only'
          'allow_auto_join'
        else
          'invite_only'
      if $scope.newSeason[type]
        $scope.newSeason[otherType] = false
    $scope.loadSeasons = ->
      $http.get("/api/match/seasons")
        .success (data) ->
          $scope.seasons = data.seasons
        .error (data) ->
          toastr.error "Failed to load seasons: #{data}"
    $scope.createSeason = ->
      $http.post("/api/match/seasons", season: $scope.newSeason)
        .success (data) ->
          toastr.success "Created new season ##{data.id}"
          $location.path("/seasons/#{data.id}")
        .error (data) ->
          toastr.error "Failed to create season"
          $scope.newSeasonError = data.errors
    $scope.loadSeasons()
]
