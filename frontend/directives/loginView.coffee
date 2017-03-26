angular.module("MagicStick.directives").directive "loginView", ->
  restrict: "E"
  templateUrl: "login.html"
  controller: [
    "$scope"
    "$http"
    "$location"
    "User"
    "toastr"
    ($scope, $http, $location, User, toastr) ->
      xtAuth = new auth0.WebAuth
        domain: MagicStick?.Env?.AUTH0_DOMAIN
        clientID: MagicStick?.Env?.AUTH0_CLIENT_ID
        scope: 'openid email name given_name family_name'
        state: 'new_account'
        redirectUri: if $location.host()
          "#{$location.protocol()}://#{$location.host()}" + \
          "#{if $location.port() then ':' + $location.port() else ''}/"
        else
          'http://localhost:9393/'

      hash = $location.hash()
      state = ''
      stateStart = hash.indexOf('state=')
      if stateStart isnt -1
        stateStart += 6 # offset
        stateEnd = hash.indexOf('&', stateStart)
        stateEnd = hash.length if stateEnd is -1
        state = hash.substring(stateStart, stateEnd)
      idStart = hash.indexOf('id_token=')
      if idStart isnt -1
        idStart += 9 # offset
        idEnd = hash.indexOf('&', idStart)
        idEnd = hash.length if idEnd is -1
        idToken = hash.substring(idStart, idEnd)
        if state is 'new_account'
          User.loginWithToken(idToken)
            .then (data) ->
              $location.hash("").replace()
              toastr.success "Successfully logged in"
              $scope.login = {}
            .catch (reason) ->
              toastr.error reason
        else if state is 'link_account'
          $http.post('/api/auth/me/identities', { token: btoa(idToken) })
            .success ->
              toastr.success "Successfully linked account"
            .error (reason) ->
              toastr.error "Failed to link account. #{reason}"
        else
          toastr.error "unexpected token received #{state}"

      $scope.redirectLogin = (to) ->
        xtAuth.authorize({ responseType: 'token', connection: to })

      $scope.tabs =
        login: yes
        signUp: no
        forgotPassword: no
      $scope.user = User
      $scope.forgotten = {}
      $scope.login = {}
      $scope.signup = {}
      $scope.signupError = {}
      $scope.attemptLogin = ->
        User.login($scope.login.username, $scope.login.password)
          .then (data) ->
            toastr.success "Successfully logged in"
            $scope.login = {}
          .catch (reason) ->
            toastr.error reason
      $scope.attemptForgotPassword = ->
        $http.post("/api/auth/forgot-password", user: $scope.forgotten)
          .success (data, status, headers) ->
            $scope.forgotten.username = ""
            $scope.forgotten.email = ""
            $scope.tabs.forgotPassword = no
            $scope.tabs.login = yes
            toastr.success "If your username and password email were correct, \
              you should see a password reset email in your inbox."
          .error (data, status, headers) ->
            toastr.error "Failed to send password reset email"
      $scope.attemptSignup = ->
        $http.post("/api/auth/users", user: $scope.signup)
          .success (data, status, headers) ->
            toastr.success "Successfully signed up, please log in"
            $scope.signup = {}
            $scope.signupError = {}
          .error (data, status, headers) ->
            toastr.error "Failed to sign up"
            $scope.signupError = data.errors
]
