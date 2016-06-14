angular.module("MagicStick.controllers").controller "PasswordResetController", [
  "$scope"
  "$log"
  "$http"
  "$routeParams"
  "toastr"
  ($scope, $log, $http, $routeParams, toastr) ->
    $scope.user = {iv: $routeParams.iv, token: $routeParams.token}
    $scope.allowReset = yes
    $scope.attemptUpdatePassword = ->
      $http.post("/api/auth/forgot-password", user: $scope.user)
        .success (data, status, headers) ->
          $scope.allowReset = no
          toastr.success "Password updated. Click the link below to log in."
        .error (data, status, headers) ->
          toastr.error "Failed to update password. Try again later."
]
