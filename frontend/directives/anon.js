/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// linked with "auth" directive
import angular from "angular";

angular.module("MagicStick.directives").directive("anon", [
  "User",
  User => ({
    restrict: "A",
    link($scope, element) {
      return $scope.$watch(
        () => User,
        function() {
          if (User.loggedIn) {
            return element.addClass("ng-hide");
          } else {
            return element.removeClass("ng-hide");
          }
        },
        true
      );
    }
  })
]);
