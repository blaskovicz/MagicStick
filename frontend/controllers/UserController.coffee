angular.module("MagicStick.controllers").controller "UserController", [
  "$scope"
  "User"
  "user"
  ($scope, User, user) ->
    $scope.user = user
    $scope.isCurrentUser = User.username is user.username
]
