angular.module("MagicStick.controllers").controller "ProfileController", [
  "$scope"
  "User"
  "$http"
  "toastr"
  "Upload"
  ($scope, User, $http, toastr, Upload) ->

    $scope.avatars = []

    $scope.$watch 'avatars', ->
      if $scope.avatars
        for avatar in $scope.avatars
          do (avatar) ->
            Upload.upload({
                  url: '/api/auth/me/avatar',
                  file: avatar
              }).success (data, status, headers, config) ->
                toastr.success "Avatar updated"
                User.get().then (response) ->
                  $scope.user = response.data

                  # hack to force image reloading
                  $scope.user.avatar_url += "?" + Math.random()

    User.get().then (response) ->
      $scope.user = response.data

    $scope.logout = -> User.logout()
    $scope.cancelEdits = ->
      $scope.user = $scope.saved
      $scope.edit = no
    $scope.editProfile = ->
      $scope.saved = angular.copy $scope.user
      $scope.edit = yes
    $scope.saveProfile = ->
      $http.post("/api/auth/me", user: $scope.user)
        .success ->
          $scope.saved = null
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
