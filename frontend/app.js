/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// app dependency config
import angular from "angular";
import Raygun from "raygun4js";
import "bootstrap";
import "angular-bootstrap";
import "angular-local-storage";
import "angular-route";
import "angular-toastr";
import "ng-file-upload";
import "angular-marked";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/css/bootstrap-theme.css";
import "./scss/app.scss";
import "angular-toastr/dist/angular-toastr.css";

angular.module("MagicStick.controllers", []);
require("./controllers/DashboardController");
require("./controllers/PasswordResetController");
require("./controllers/ProfileController");
require("./controllers/SeasonDashboardController");
require("./controllers/SeasonManageController");
require("./controllers/UserController");

angular.module("MagicStick.services", []);
require("./services/User");

angular.module("MagicStick.directives", []);
require("./directives/anon");
require("./directives/auth");
require("./directives/formInput");
require("./directives/leaderboard");
require("./directives/loginView");
require("./directives/memberSeasonView");
require("./directives/seasonList");
require("./directives/userView");

const app = angular.module("MagicStick", [
  "LocalStorageModule",
  "ngRoute",
  "toastr",
  "ui.bootstrap",
  "ngFileUpload",
  "hc.marked",
  "MagicStick.controllers",
  "MagicStick.services",
  "MagicStick.directives"
]);

// client routing config
app
  .config([
    "$routeProvider",
    "$locationProvider",
    function($routeProvider, $locationProvider) {
      $routeProvider
        .when("/", {
          template: require("./views/dashboard.html"),
          controller: "DashboardController"
        })
        .when("/password-reset/:token/:iv", {
          template: require("./views/password-reset.html"),
          controller: "PasswordResetController"
        })
        .when("/profile", {
          template: require("./views/profile.html"),
          controller: "ProfileController",
          auth: true
        })
        .when("/users/:username", {
          template: require("./views/user-profile.html"),
          controller: "UserController",
          auth: true,
          resolve: {
            user: [
              "$route",
              "$q",
              "$http",
              function($route, $q, $http) {
                const promise = $q.defer();
                const { username } = $route.current.params;
                $http
                  .get(`/api/users/${username}`)
                  .success(data => promise.resolve(data))
                  .error(data => promise.reject(data));
                return promise.promise;
              }
            ]
          }
        })
        .when("/seasons", {
          template: require("./views/seasons.html"),
          controller: "SeasonDashController",
          auth: true
        })
        .when("/seasons/:seasonId", {
          template: require("./views/season-manage.html"),
          controller: "SeasonManageController",
          auth: true,
          resolve: {
            season: [
              "$route",
              "$q",
              "$http",
              "$modal",
              function($route, $q, $http, $modal) {
                const modal = $modal.open({
                  backdrop: "static",
                  template: `\
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
</div>`,
                  keyboard: false,
                  size: "lg"
                });
                // TODO move some of the $http stuff into service objects
                const promise = $q.defer();
                const { seasonId } = $route.current.params;
                if (!/^\d+$/.test(seasonId)) {
                  modal.close();
                  promise.reject("Invalid season id, must be numeric");
                } else {
                  $http
                    .get(`/api/match/seasons/${seasonId}`)
                    .success(function(data) {
                      modal.close();
                      return promise.resolve(data);
                    })
                    .error(function(data) {
                      modal.close();
                      return promise.reject(data);
                    });
                }
                return promise.promise;
              }
            ]
          }
        })
        .otherwise({ redirectTo: "/" });
      $locationProvider.html5Mode(false);
      return $locationProvider.hashPrefix("!");
    }
  ])
  .config(["$logProvider", $logProvider => $logProvider.debugEnabled(true)])
  .config([
    "markedProvider",
    markedProvider =>
      markedProvider.setOptions({
        gfm: true,
        tables: true
      })
  ])
  .config([
    "$httpProvider",
    $httpProvider =>
      $httpProvider.interceptors.push([
        "$q",
        "$rootScope",
        "$location",
        "$log",
        "toastr",
        // cannot directly talk to User service due to circular dep
        "localStorageService",
        function($q, $rootScope, $location, $log, toastr, localStorageService) {
          const apiRequest = c =>
            c.url !== "/api/auth/login" && c.url.indexOf("/api") === 0;
          return {
            requestError(request) {
              $log.info("requestError", request);
              return $q.reject(request);
            },
            request(config) {
              if (apiRequest(config)) {
                const u = localStorageService.get("currentUser");
                if (
                  (u != null ? u.exp : undefined) != null &&
                  (u != null ? u.token : undefined) != null
                ) {
                  const exp = new Date(u.exp * 1000);
                  // check if we expire in 2 seconds or less
                  if (exp <= new Date(new Date().getTime() + 5 * 1000)) {
                    $log.info(`jwt has expired at ${exp}, forcing logout`);
                    $location.hash("").replace();
                    $location.path("/").replace();
                    toastr.warning(
                      "Your login token has expired. Please re-login."
                    );
                    $rootScope.$broadcast("currentUser:login:force_logout");
                  }
                }
              }
              return config || $q.when(config);
            },
            responseError(response) {
              $log.info("responseError", response);
              if (apiRequest(response.config)) {
                if (response.status === 401) {
                  // expired token
                  $log.info("jwt has expired during request, forcing logout");
                  $location.hash("").replace();
                  $location.path("/").replace();
                  toastr.warning(
                    "Your login token has expired. Please re-login."
                  );
                  $rootScope.$broadcast("currentUser:login:force_logout");
                }
              }
              return $q.reject(response);
            },
            response(response) {
              if (apiRequest(response.config)) {
                if (response.status === 401) {
                  // expired token
                  $log.info("jwt has expired during request, forcing logout");
                  $location.hash("").replace();
                  $location.path("/").replace();
                  toastr.warning(
                    "Your login token has expired. Please re-login."
                  );
                  $rootScope.$broadcast("currentUser:login:force_logout");
                }
              }
              return response || $q.when(response);
            }
          };
        }
      ])
  ])
  .config([
    "$provide",
    function($provide) {
      if (typeof MagicStick !== "object") {
        // eslint-disable-next-line no-console
        console.info("Skipping Raygun init");
        return;
      }

      // raygun
      Raygun("apiKey", MagicStick.Env.RAYGUN_API_KEY);
      Raygun("enableCrashReporting", true);
      Raygun("options", {
        allowInsecureSubmissions: true
      });
      Raygun("setVersion", MagicStick.Env.MAGIC_STICK_VERSION);
      Raygun("filterSensitiveData", ["password", "email", "token"]);
      Raygun("withTags", `ENV:${MagicStick.Env.RACK_ENV}`);

      return $provide.decorator("$exceptionHandler", [
        "$delegate",
        "$log",
        ($delegate, $log) =>
          function(exception, cause) {
            $log.warn("Sending to Raygun", exception, cause);
            Raygun("send", { exception, cause });
            return $delegate(exception, cause);
          }
      ]);
    }
  ]);

// auth shim
// - to be combined with auth directive
app.run([
  "$rootScope",
  "$location",
  "$window",
  "User",
  "toastr",
  function($rootScope, $location, $window, User, toastr) {
    User.loadFromStorage();
    const notAuthorizedRedirect = function() {
      $location.path("/").replace();
      return toastr.warning("You're not authorized to access this page");
    };
    $rootScope.$on("$routeChangeError", () =>
      toastr.warning("An error occurred loading this page")
    );
    return $rootScope.$on("$routeChangeStart", function(event, next) {
      if (!next.auth) {
        return;
      }
      const type = typeof next.auth;
      if (type === "boolean" && next.auth) {
        if (User.loggedIn) {
          return;
        }
      } else if (type === "object" && next.auth instanceof Array) {
        for (let role of Array.from(next.auth)) {
          if (
            (User.roles != null ? User.roles[role] : undefined) &&
            User.loggedIn
          ) {
            return;
          }
        }
      } else {
        throw new Error("Unsupported auth config provided");
      }
      return notAuthorizedRedirect();
    });
  }
]);
