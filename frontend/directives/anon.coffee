# linked with "auth" directive
angular.module("MagicStick.directives").directive("anon", [
  "User"
  (User) ->
    restrict: 'A'
    link: ($scope, element, attrs) ->
      $scope.$watch(
        -> User,
        ->
          if User.loggedIn
            element.addClass('ng-hide')
          else
            element.removeClass('ng-hide')
        , true
      )
])
