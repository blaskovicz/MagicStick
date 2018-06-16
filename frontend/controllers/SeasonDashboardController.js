/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import moment from "moment";

angular.module("MagicStick.controllers").controller("SeasonDashController", [
  "$scope",
  "$http",
  "User",
  "toastr",
  "$location",
  function($scope, $http, User, toastr, $location) {
    $scope.newSeason = {
      name: "",
      description: "",
      starts: moment().toDate(),
      ends: moment()
        .add(1, "months")
        .toDate(),
      allow_auto_join: true,
      invite_only: false
    };
    // const savedSeason = angular.copy($scope.newSeason);
    $scope.newSeasonError = {};
    $scope.user = User;
    $scope.assertJoinType = function(type) {
      const otherType =
        type === "invite_only" ? "allow_auto_join" : "invite_only";
      if ($scope.newSeason[type]) {
        return ($scope.newSeason[otherType] = false);
      }
    };
    $scope.loadSeasons = () =>
      $http
        .get("/api/match/seasons")
        .success(data => ($scope.seasons = data.seasons))
        .error(data => toastr.error(`Failed to load seasons: ${data}`));
    $scope.createSeason = () =>
      $http
        .post("/api/match/seasons", { season: $scope.newSeason })
        .success(function(data) {
          toastr.success(`Created new season #${data.id}`);
          return $location.path(`/seasons/${data.id}`);
        })
        .error(function(data) {
          toastr.error("Failed to create season");
          return ($scope.newSeasonError = data.errors);
        });
    return $scope.loadSeasons();
  }
]);
