# app dependency config
app = angular.module("MagicStick", [
  "ngRoute"
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
      .otherwise(redirectTo: "/")
    $locationProvider.html5Mode true

]).config([
  "$logProvider"
  ($logProvider) ->
    $logProvider.debugEnabled true
])
