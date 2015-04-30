# based on
# http://www.jonsamwell.com/url-route-authorization-and-security-in-angular/
angular.module("MagicStick.directives").directive("auth", [
  "User"
  (User) ->
    restrict: 'A'
    link: ($scope, element, attrs) ->
      $scope.$watch(
        -> User,
        ->
          $scope.username = User.username
          $scope.avatar_url = User.avatar_url
          authed = false
          rolesRequired = attrs.auth
          if rolesRequired is ""
            authed = true if User.loggedIn
          else
            roles = rolesRequired.split(/\s*,\s*/)
            for role in roles
              authed = true if User.roles?[role] and User.loggedIn

          if authed
            element.removeClass('ng-hide')
          else
            element.addClass('ng-hide')
        , true
      )
])
