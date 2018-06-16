/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular.module("MagicStick.controllers").controller("UserController", [
  "$scope",
  "User",
  "user",
  function($scope, User, user) {
    $scope.user = user;
    $scope.isCurrentUser =
      User.username === (user != null ? user.username : undefined);
    $scope.slack = { in_slack: false };
    return User.slackInfo().then(response => ($scope.slack = response.data));
  }
]);
