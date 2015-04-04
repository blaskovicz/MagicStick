angular.module("MagicStick.directives").directive "loginView", ->
  restrict: "E"
  templateUrl: "login.html"
  controller: [
    "$scope"
    "$http"
    "User"
    "toastr"
    ($scope, $http, User, toastr) ->
      $scope.user = User
      $scope.login = {}
      $scope.signup = {}
      $scope.signupError = {}
      $scope.attemptLogin = ->
        $http.post("/api/auth/login", $scope.login)
          .success (data, status, headers) ->
            toastr.success "Successfully logged in"
            User.username = $scope.login.username
            User.loggedIn = true
            $scope.login = {}
          .error (data, status, headers) ->
            toastr.error data
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
