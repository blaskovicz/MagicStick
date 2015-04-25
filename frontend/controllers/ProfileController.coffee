angular.module("MagicStick.controllers").controller "ProfileController", [
  "$scope"
  "User"
  "$http"
  "toastr"
  ($scope, User, $http, toastr) ->
    $http.get("/api/auth/me").then (response) ->
      $scope.user = response.data

    $scope.logout = -> User.logout()
    $scope.editProfile = -> $scope.edit = true
    $scope.saveProfile = ->
      $http.post("/api/auth/me", user: $scope.user)
        .success ->
          $scope.edit = false
          $scope.errors = undefined

          toastr.success "Profile updated"

          User.login $scope.user.username, $scope.user.password

          $scope.user.password = undefined
          $scope.user.passwordCurrent = undefined
          $scope.user.passwordConfirmation = undefined

        .error (reason) ->
          $scope.errors = reason?.errors
          toastr.error "Failed to update profile"
]
