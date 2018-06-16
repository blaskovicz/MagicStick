/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// based on
// http://www.jonsamwell.com/url-route-authorization-and-security-in-angular/
import angular from "angular";

angular.module("MagicStick.directives").directive("auth", [
  "User",
  User => ({
    restrict: "A",
    link($scope, element, attrs) {
      return $scope.$watch(
        () => User,
        function() {
          $scope.username = User.username;
          $scope.avatar_url = User.avatar_url;
          let authed = false;
          const rolesRequired = attrs.auth;
          if (rolesRequired === "") {
            if (User.loggedIn) {
              authed = true;
            }
          } else {
            const roles = rolesRequired.split(/\s*,\s*/);
            for (let role of Array.from(roles)) {
              if (
                (User.roles != null ? User.roles[role] : undefined) &&
                User.loggedIn
              ) {
                authed = true;
              }
            }
          }

          if (authed) {
            return element.removeClass("ng-hide");
          } else {
            return element.addClass("ng-hide");
          }
        },
        true
      );
    }
  })
]);
