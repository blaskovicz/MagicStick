angular.module("MagicStick.directives").directive "memberSeasonView", ->
  restrict: "E"
  templateUrl: "member-season-view.html"
  controller: [
    "$scope"
    "$http"
    "User"
    "toastr"
    ($scope, $http, User, toastr) ->
      $scope.seasons = []
      refreshSeasons = () ->
        return unless User.loggedIn
        $http.get("/api/match/seasons", params: member: true)
          .success (data) ->
            $scope.seasons = data?.seasons
      refreshSeasons()
      $scope.$on("currentUser:login:changed", -> refreshSeasons())
]
