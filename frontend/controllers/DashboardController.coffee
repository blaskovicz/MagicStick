angular.module("MagicStick.controllers").controller "DashboardController", [
  "$scope"
  "User"
  ($scope, User) ->
    $scope.user = User
]
