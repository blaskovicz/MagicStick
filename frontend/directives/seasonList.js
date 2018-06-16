/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular.module("MagicStick.directives").directive("seasonList", () => ({
  restrict: "E",
  scope: {
    seasons: "&"
  },
  template: require("../views/season-list.html"),
  controller: [
    "$location",
    "$scope",
    ($location, $scope) =>
      ($scope.openSeason = function(event, season) {
        event.stopPropagation();
        return $location.path(`/seasons/${season.id}`);
      })
  ]
}));
