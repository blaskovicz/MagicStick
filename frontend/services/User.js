/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import { jwt_decode, base64_url_decode } from "../lib/jwt-decode";

angular.module("MagicStick.services").factory("User", [
  "$http",
  "$log",
  "$q",
  "localStorageService",
  "$rootScope",
  "$location",
  function($http, $log, $q, localStorageService, $rootScope, $location) {
    return new class User {
      constructor() {
        this.loggedIn = false;
        this.username = "";
        this.roles = {};
        $rootScope.$on("currentUser:login:force_logout", () => {
          $log.info("performing logout");
          return this.logout();
        });
      }
      clone() {
        return {
          username: this.username,
          id: this.id,
          name: this.name,
          token: this.token,
          exp: this.exp,
          catchphrase: this.catchphrase,
          avatar_url: this.avatar_url
        };
      }
      parseToken() {
        if (this.token == null) {
          return;
        }
        return jwt_decode(this.token);
      }
      loadFromStorage() {
        const user = localStorageService.get("currentUser");
        if (user == null) {
          return;
        }
        if (user.token != null) {
          this.token = user.token;
        }
        if (user.exp != null) {
          this.exp = user.exp;
        }
        if (user.username != null) {
          this.username = user.username;
        }
        if (user.authHeader != null) {
          this.authHeader = user.authHeader;
        }
        if (this.token == null) {
          this.logout(true);
          return;
        }
        $http.defaults.headers.common["Authorization"] = this.authHeader;
        try {
          this.parsePrincipal(__guard__(this.parseToken(), x => x.user));
          this.loggedIn = true;
          return this.broadcastLoginStateChange();
        } catch (error) {
          return this.logout(true);
        }
      }
      loginWithToken(token) {
        return this._login(`Bearer ${token != null ? token : ""}`);
      }
      login(username, password) {
        return this._login(
          `Basic ${btoa(
            (username != null ? username : "") +
              ":" +
              (password != null ? password : "")
          )}`
        );
      }
      _login(authHeader) {
        const promise = $q.defer();
        $http
          .post("/api/auth/login", "", {
            headers: { Authorization: authHeader }
          })
          .success(data => {
            // header.payload.sig
            let payload;
            try {
              this.token = base64_url_decode(data.token);
              payload = this.parseToken();
            } catch (e) {
              this.token = null;
              promise.reject("failed to log in");
              return;
            }
            this.exp = payload.exp;
            $http.defaults.headers.common[
              "Authorization"
            ] = this.authHeader = `Bearer ${this.token}`;
            this.loggedIn = true;
            this.parsePrincipal(payload.user);
            this.saveToStorage();
            this.broadcastLoginStateChange();
            return promise.resolve();
          })
          .error(data =>
            promise.reject(
              (data != null ? data.errors : undefined) != null
                ? data != null
                  ? data.errors
                  : undefined
                : "Invalid credentials"
            )
          );
        return promise.promise;
      }
      slackInfo() {
        return $http.get("/api/auth/me/slack");
      }
      get() {
        return $http.get("/api/auth/me");
      }
      loadPrincipal() {
        return this.get()
          .success(data => {
            return this.parsePrincipal(data);
          })
          .error((data, status) => {
            $log.warn(`Couldn't load auth data: ${data}`);
            if (status === 401) {
              return this.logout();
            }
          });
      }
      parsePrincipal(data) {
        if (data == null) {
          return;
        }
        this.id = data.id;
        this.name = data.name;
        this.username = data.username;
        this.avatar_url = data.avatar_url;
        this.catchphrase = data.catchphrase;
        this.roles = {};
        return Array.from(data.roles).map(
          role => (this.roles[role.name] = true)
        );
      }
      logout(quiet) {
        if (quiet == null) {
          quiet = false;
        }
        this.id = null;
        this.token = null;
        this.exp = null;
        this.loggedIn = false;
        this.name = "";
        this.catchphrase = "";
        this.username = "";
        this.roles = {};
        this.avatar_url = null;
        delete $http.defaults.headers.common["Authorization"];
        localStorageService.set("currentUser", null);
        if (quiet) {
          return;
        }
        this.broadcastLoginStateChange();
        return $location.path("/");
      }
      saveToStorage() {
        return localStorageService.set("currentUser", this);
      }
      broadcastLoginStateChange() {
        return $rootScope.$broadcast("currentUser:login:changed");
      }
    }();
  }
]);

function __guard__(value, transform) {
  return typeof value !== "undefined" && value !== null
    ? transform(value)
    : undefined;
}
