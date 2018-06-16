/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import { WebAuth } from "auth0-js";

angular.module("MagicStick.directives").directive("loginView", () => ({
  restrict: "E",
  template: require("../views/login.html"),
  controller: [
    "$scope",
    "$http",
    "$location",
    "User",
    "toastr",
    function($scope, $http, $location, User, toastr) {
      const xtAuth = new WebAuth({
        domain: __guard__(
          typeof MagicStick !== "undefined" && MagicStick !== null
            ? MagicStick.Env
            : undefined,
          x => x.AUTH0_DOMAIN
        ),
        clientID: __guard__(
          typeof MagicStick !== "undefined" && MagicStick !== null
            ? MagicStick.Env
            : undefined,
          x1 => x1.AUTH0_CLIENT_ID
        ),
        scope: "openid email name given_name family_name",
        state: "new_account",
        redirectUri: $location.host()
          ? `${$location.protocol()}://${$location.host()}` +
            `${$location.port() ? `:${$location.port()}` : ""}/`
          : "http://localhost:9393/"
      });

      const hash = $location.hash();
      let state = "";
      let stateStart = hash.indexOf("state=");
      if (stateStart !== -1) {
        stateStart += 6; // offset
        let stateEnd = hash.indexOf("&", stateStart);
        if (stateEnd === -1) {
          stateEnd = hash.length;
        }
        state = hash.substring(stateStart, stateEnd);
      }
      let idStart = hash.indexOf("id_token=");
      if (idStart !== -1) {
        idStart += 9; // offset
        let idEnd = hash.indexOf("&", idStart);
        if (idEnd === -1) {
          idEnd = hash.length;
        }
        const idToken = hash.substring(idStart, idEnd);
        if (state === "new_account") {
          User.loginWithToken(idToken)
            .then(function() {
              $location.hash("").replace();
              toastr.success("Successfully logged in");
              return ($scope.login = {});
            })
            .catch(reason => toastr.error(reason));
        } else if (state === "link_account") {
          $http
            .post("/api/auth/me/identities", { token: btoa(idToken) })
            .success(() => toastr.success("Successfully linked account"))
            .error(reason => toastr.error(`Failed to link account. ${reason}`));
        } else {
          toastr.error(`unexpected token received ${state}`);
        }
      }

      $scope.redirectLogin = to =>
        xtAuth.authorize({ responseType: "token", connection: to });

      $scope.tabs = {
        login: true,
        signUp: false,
        forgotPassword: false
      };
      $scope.user = User;
      $scope.forgotten = {};
      $scope.login = {};
      $scope.signup = {};
      $scope.signupError = {};
      $scope.attemptLogin = () =>
        User.login($scope.login.username, $scope.login.password)
          .then(function() {
            toastr.success("Successfully logged in");
            return ($scope.login = {});
          })
          .catch(reason => toastr.error(reason));
      $scope.attemptForgotPassword = () =>
        $http
          .post("/api/auth/forgot-password", { user: $scope.forgotten })
          .success(function() {
            $scope.forgotten.username = "";
            $scope.forgotten.email = "";
            $scope.tabs.forgotPassword = false;
            $scope.tabs.login = true;
            return toastr.success(`If your username and password email were correct, \
you should see a password reset email in your inbox.`);
          })
          .error(() => toastr.error("Failed to send password reset email"));
      return ($scope.attemptSignup = () =>
        $http
          .post("/api/auth/users", { user: $scope.signup })
          .success(function() {
            toastr.success("Successfully signed up, please log in");
            $scope.signup = {};
            return ($scope.signupError = {});
          })
          .error(function(data) {
            toastr.error("Failed to sign up");
            return ($scope.signupError = data.errors);
          }));
    }
  ]
}));

function __guard__(value, transform) {
  return typeof value !== "undefined" && value !== null
    ? transform(value)
    : undefined;
}
