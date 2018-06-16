/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import _ from "lodash";
import { WebAuth } from "auth0-js";

angular.module("MagicStick.controllers").controller("ProfileController", [
  "$scope",
  "localStorageService",
  "User",
  "$http",
  "$location",
  "toastr",
  "Upload",
  function(
    $scope,
    localStorageService,
    User,
    $http,
    $location,
    toastr,
    Upload
  ) {
    $scope.user = {};
    $scope.avatars = [];
    $scope.slack = { in_slack: false };

    $scope.$watch("avatars", function() {
      if (!$scope.avatars) {
        return;
      }
      return Array.from($scope.avatars).map(avatar =>
        (avatar =>
          Upload.upload({
            url: "/api/auth/me/avatar",
            file: avatar
          })
            .success(function() {
              loadUser();
              return toastr.success("Avatar updated");
            })
            .error(function(data) {
              let left;
              return toastr.error(
                "Failed to upload avatar: " +
                  `${
                    (left = __guard__(
                      __guard__(
                        data != null ? data.errors : undefined,
                        x1 => x1.avatar
                      ),
                      x => x.join("; ")
                    )) != null
                      ? left
                      : "try again later."
                  }`
              );
            }))(avatar)
      );
    });

    var loadUser = function() {
      User.slackInfo().then(response => ($scope.slack = response.data));
      return User.get().then(function(response) {
        $scope.user = response.data;
        // hack to force image reloading
        $scope.user.avatar_url += `?${Math.random()}`;
        User.avatar_url = $scope.user.avatar_url;
        $scope.has_facebook = _.find(
          $scope.user.user_identities,
          id => id.provider_id.indexOf("facebook") === 0
        );
        return ($scope.has_google = _.find(
          $scope.user.user_identities,
          id => id.provider_id.indexOf("google-oauth2") === 0
        ));
      });
    };

    loadUser();

    $scope.toggleConnection = function(name, state) {
      const nextState = state
        ? "unlink your account from"
        : "link your account to";
      if (!confirm(`Do you really want to ${nextState} ${name}?`)) {
        return;
      }
      if (!state) {
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
          state: "link_account",
          redirectUri: $location.host()
            ? `${$location.protocol()}://${$location.host()}` +
              `${$location.port() ? `:${$location.port()}` : ""}/`
            : "http://localhost:9393/"
        });
        xtAuth.authorize({ responseType: "token", connection: name });
        return;
      }
      return $http
        .delete(`/api/auth/me/identities/${state.id}`)
        .success(() => loadUser())
        .error(() =>
          toastr.error(`Failed to remove ${name} link. Try again later.`)
        );
    };

    // obv this may break if a user has n accounts, but they should only have 1
    $scope.slackInviteSent = localStorageService.get("slackInviteSent");
    $scope.sendSlackInvite = () =>
      $http
        .put("/api/auth/me/slack", {})
        .success(function() {
          localStorageService.set("slackInviteSent", true);
          $scope.slackInviteSent = true;
          return toastr.success("Check your inbox, an invite was just sent!");
        })
        .error(() => toastr.error("Failed to send invite. Try again later."));
    $scope.logout = () => User.logout();
    $scope.cancelEdits = function() {
      $scope.user = $scope.saved;
      return ($scope.edit = false);
    };
    $scope.editProfile = function() {
      $scope.saved = angular.copy($scope.user);
      return ($scope.edit = true);
    };
    return ($scope.saveProfile = () =>
      $http
        .post("/api/auth/me", { user: $scope.user })
        .success(function() {
          $scope.saved = null;
          $scope.edit = false;
          $scope.errors = undefined;

          toastr.success("Profile updated");

          User.login($scope.user.username, $scope.user.password);

          $scope.user.password = undefined;
          $scope.user.passwordCurrent = undefined;
          return ($scope.user.passwordConfirmation = undefined);
        })
        .error(function(reason) {
          $scope.errors = reason != null ? reason.errors : undefined;
          return toastr.error("Failed to update profile");
        }));
  }
]);

function __guard__(value, transform) {
  return typeof value !== "undefined" && value !== null
    ? transform(value)
    : undefined;
}
