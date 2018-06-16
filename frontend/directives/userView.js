/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular.module("MagicStick.directives").directive("userView", () => ({
  restrict: "E",
  scope: {
    user: "&"
  },
  template: require("../views/user.html"),
  controller: [
    "$scope",
    "$location",
    ($scope, $location) =>
      ($scope.view = function(event) {
        event.stopPropagation();
        return $location.path(`/users/${$scope.user().username}`);
      })
  ]
}));
