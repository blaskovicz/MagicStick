angular.module("MagicStick.directives").directive "loginView", ->
  restrict: "E"
  templateUrl: "login.html"
  controller: [
    "$scope"
    "$http"
    "User"
    "toastr"
    ($scope, $http, User, toastr) ->
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
