# app dependency config
app = angular.module("MagicStick", [
  "LocalStorageModule"
  "ngRoute"
  "toastr"
  "ui.bootstrap"
  "ngFileUpload"
  "hc.marked"
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
      .when("/password-reset/:token/:iv", {
        templateUrl: "password-reset.html"
        controller: "PasswordResetController"
      })
      .when("/profile", {
        templateUrl: "profile.html"
        controller: "ProfileController"
        auth: true
      })
      .when("/users/:username", {
        templateUrl: "user-profile.html"
        controller: "UserController"
        auth: true
        resolve:
          user: [
            "$route", "$q", "$http",
            ($route, $q, $http) ->
              promise = $q.defer()
              username = $route.current.params.username
              $http.get("/api/users/#{username}")
                .success (data) -> promise.resolve(data)
                .error (data) -> promise.reject(data)
              promise.promise
          ]
      })
      .when("/seasons", {
        templateUrl: "seasons.html"
        controller: "SeasonDashController"
        auth: true
      })
      .when("/seasons/:seasonId", {
        templateUrl: "season-manage.html"
        controller: "SeasonManageController"
        auth: true
        resolve:
          season: [
            "$route"
            "$q"
            "$http"
            "$modal"
            ($route, $q, $http, $modal) ->
              modal = $modal.open {
                backdrop: "static"
                template: """
                <div>
                  <div class="modal-header">
                    <h3 class="modal-title">
                      Loading...
                    </h3>
                  </div>
                  <div class="modal-body">
                    <progressbar
                      class="progress-striped active"
                      value="'100'">
                    </progressbar>
                  </div>
                </div>"""
                keyboard: no
                size: "lg"
              }
              #TODO move some of the $http stuff into service objects
              promise = $q.defer()
              seasonId = $route.current.params.seasonId
              if not /^\d+$/.test(seasonId)
                modal.close()
                promise.reject("Invalid season id, must be numeric")
              else
                $http.get("/api/match/seasons/#{seasonId}")
                  .success (data) ->
                    modal.close()
                    promise.resolve(data)
                  .error (data) ->
                    modal.close()
                    promise.reject(data)
              promise.promise
          ]
      })
      .otherwise(redirectTo: "/")
    $locationProvider.html5Mode false
    $locationProvider.hashPrefix '!'

]).config([
  "$logProvider"
  ($logProvider) ->
    $logProvider.debugEnabled true
]).config([
  "markedProvider"
  (markedProvider) ->
    markedProvider.setOptions {
      gfm: true
      tables: true
    }
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
    $rootScope.$on "$routeChangeError", ->
      toastr.warning "An error occurred loading this page"
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
