angular.module("MagicStick.controllers").controller "UserController", [
  "$scope"
  "user"
  ($scope, user) ->
    $scope.user = user
]
