/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular.module("MagicStick.controllers").controller("PasswordResetController", [
  "$scope",
  "$log",
  "$http",
  "$routeParams",
  "toastr",
  function($scope, $log, $http, $routeParams, toastr) {
    $scope.user = { iv: $routeParams.iv, token: $routeParams.token };
    $scope.allowReset = true;
    return ($scope.attemptUpdatePassword = () =>
      $http
        .post("/api/auth/forgot-password", { user: $scope.user })
        .success(function() {
          $scope.allowReset = false;
          return toastr.success(
            "Password updated. Click the link below to log in."
          );
        })
        .error(() =>
          toastr.error("Failed to update password. Try again later.")
        ));
  }
]);
