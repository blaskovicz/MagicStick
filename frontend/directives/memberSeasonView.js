/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
angular.module("MagicStick.directives").directive("memberSeasonView", () => ({
  restrict: "E",
  template: require("../views/member-season-view.html"),
  controller: [
    "$scope",
    "$http",
    "User",
    function($scope, $http, User) {
      $scope.seasons = [];
      const refreshSeasons = function() {
        if (!User.loggedIn) {
          return;
        }
        return $http
          .get("/api/match/seasons", { params: { member: true } })
          .success(
            data => ($scope.seasons = data != null ? data.seasons : undefined)
          );
      };
      refreshSeasons();
      return $scope.$on("currentUser:login:changed", () => refreshSeasons());
    }
  ]
}));
