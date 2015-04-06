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
        User.login($scope.login.username, $scope.login.password)
          .then (data) ->
            toastr.success "Successfully logged in"
            $scope.login = {}
          .catch (reason) ->
            toastr.error reason
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
