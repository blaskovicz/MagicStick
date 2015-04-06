angular.module("MagicStick.directives").directive "userView", ->
  restrict: "E"
  templateUrl: "user.html"
  controller: [
    "$scope"
    "User"
    ($scope, User) ->
      $scope.user = User
      $scope.logout = -> User.logout()
  ]

