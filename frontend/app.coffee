# app dependency config
app = angular.module("MagicStick", [
  "LocalStorageModule"
  "ngRoute"
  "toastr"
  "ui.bootstrap"
  "MagicStick.controllers"
  "MagicStick.services"
  "MagicStick.directives"
  "MagicStick.filters"
  "MagicStick.templates"
])
angular.module("MagicStick.controllers", [])
angular.module("MagicStick.services", [])
angular.module("MagicStick.directives", [])
angular.module("MagicStick.filters", [])
angular.module("MagicStick.templates", [])

# client routing config
app.config([
  "$routeProvider"
  "$locationProvider"
  ($routeProvider, $locationProvider) ->
    $routeProvider
      .when("/", {
        templateUrl: "dashboard.html"
        controller: "DashboardController"
      })
      .when("/seasons", {
        templateUrl: "seasons.html"
        controller: "SeasonDashController"
        auth: true
      })
      .otherwise(redirectTo: "/")
    $locationProvider.html5Mode false
    $locationProvider.hashPrefix '!'

]).config([
  "$logProvider"
  ($logProvider) ->
    $logProvider.debugEnabled true
])

# auth shim
# - to be combined with auth directive
app.run([
  "$rootScope"
  "$location"
  "$window"
  "User"
  "toastr"
  ($rootScope, $location, $window, User, toastr) ->
    User.loadFromStorage()
    notAuthorizedRedirect = ->
      $location.path("/").replace()
      toastr.warning "You're not authorized to access this page"
    $rootScope.$on "$routeChangeStart", (event, next) ->
      return unless next.auth
      type = typeof next.auth
      if type is "boolean" and next.auth
        return if User.loggedIn
      else if type is "object" and next.auth instanceof Array
        for role in next.auth
          return if User.roles?[role] and User.loggedIn
      else
        throw new Error "Unsupported auth config provided"
      notAuthorizedRedirect()
])
