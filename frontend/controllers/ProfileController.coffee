angular.module("MagicStick.controllers").controller "ProfileController", [
  "$scope"
  "localStorageService"
  "User"
  "$http"
  "toastr"
  "Upload"
  ($scope, localStorageService, User, $http, toastr, Upload) ->

    $scope.avatars = []

    $scope.$watch 'avatars', ->
      return unless $scope.avatars
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

    $scope.slack =
      in_slack: false
    User.slackInfo().then (response) ->
      $scope.slack = response.data
    # obv this may break if a user has n accounts, but they should only have 1
    $scope.slackInviteSent = localStorageService.get("slackInviteSent")
    $scope.sendSlackInvite = () ->
      $http.put("/api/auth/me/slack", {})
        .success ->
          localStorageService.set("slackInviteSent", true)
          $scope.slackInviteSent = true
          toastr.success "Check your inbox, an invite was just sent!"
        .error (reason) ->
          toastr.error "Failed to send invite. Try again later."
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
