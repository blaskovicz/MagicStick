/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular
  .module("MagicStick.controllers")
  .controller("DashboardController", [
    "$scope",
    "User",
    ($scope, User) => ($scope.user = User)
  ]);
