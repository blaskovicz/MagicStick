angular.module("MagicStick.controllers").controller "ProfileController", [
  "$scope"
  "localStorageService"
  "User"
  "$http"
  "$location"
  "toastr"
  "Upload"
  ($scope, localStorageService, User, $http, $location, toastr, Upload) ->
    $scope.user = {}
    $scope.avatars = []
    $scope.slack =
      in_slack: false

    $scope.$watch 'avatars', ->
      return unless $scope.avatars
      for avatar in $scope.avatars
        do (avatar) ->
          Upload.upload({
            url: '/api/auth/me/avatar',
            file: avatar
          })
            .success (data, status, headers, config) ->
              loadUser()
              toastr.success "Avatar updated"
            .error (data) ->
              toastr.error "Failed to upload avatar: " +
                "#{data?.errors?.avatar?.join('; ') ? 'try again later.'}"

    loadUser = () ->
      User.slackInfo().then (response) ->
        $scope.slack = response.data
      User.get().then (response) ->
        $scope.user = response.data
        # hack to force image reloading
        $scope.user.avatar_url += "?" + Math.random()
        User.avatar_url = $scope.user.avatar_url
        $scope.has_facebook = _.find $scope.user.user_identities, (id) ->
          id.provider_id.indexOf('facebook') is 0
        $scope.has_google = _.find $scope.user.user_identities, (id) ->
          id.provider_id.indexOf('google-oauth2') is 0

    loadUser()

    $scope.toggleConnection = (name, state) ->
      nextState = if state
        'unlink your account from'
      else
        'link your account to'
      return unless confirm("Do you really want to #{nextState} #{name}?")
      unless state
        xtAuth = new auth0.WebAuth
          domain: MagicStick?.Env?.AUTH0_DOMAIN
          clientID: MagicStick?.Env?.AUTH0_CLIENT_ID
          scope: 'openid email name given_name family_name'
          state: 'link_account'
          redirectUri: if $location.host()
            "#{$location.protocol()}://#{$location.host()}" + \
            "#{if $location.port() then ':' + $location.port() else ''}/"
          else
            'http://localhost:9393/'
        xtAuth.authorize({ responseType: 'token', connection: name })
        return
      $http.delete("/api/auth/me/identities/#{state.id}")
        .success ->
          loadUser()
        .error ->
          toastr.error "Failed to remove #{name} link. Try again later."

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
