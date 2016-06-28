angular.module("MagicStick.directives").directive "seasonList", ->
  restrict: "E"
  scope:
    seasons: "&"
  templateUrl: "season-list.html"
  controller: [
    "$location"
    "$scope"
    ($location, $scope) ->
      $scope.openSeason = (event, season) ->
        event.stopPropagation()
        $location.path "/seasons/#{season.id}"
  ]
