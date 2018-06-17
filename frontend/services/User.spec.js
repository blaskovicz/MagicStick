/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

describe("MagicStick.services.User", function() {
  // created with https://jwt.io/
  const validJwt =
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsImV4cCI6MTQ4OTI0Njg0OTAsImlzcyI6Im1hZ2ljLXN0aWNrIiwidXNlciI6eyJpZCI6MSwidXNlcm5hbWUiOiJ6YWNoIiwiZW1haWwiOiJlbWFpbEBtYWdpYy1zdGljay5oZXJva3VhcHAuY29tIiwiY2F0Y2hwaHJhc2UiOiJob3dzIGl0IGdvaW4nIGJyb3MiLCJjcmVhdGVkX2F0IjoiMjAxNS0wNC0xOCAxMDo1NDo1NSAtMDQwMCIsInVwZGF0ZWRfYXQiOiIyMDE3LTAzLTExIDA5OjQwOjMxIC0wNTAwIiwibGFzdF9sb2dpbiI6IjIwMTctMDMtMTEgMDk6NDA6MzEgLTA1MDAiLCJuYW1lIjoiWmFjaCBBdHRhY2siLCJhdmF0YXJfY29udGVudF90eXBlIjoiaW1hZ2UvanBlZyIsInJvbGVzIjpbeyJuYW1lIjoiYWRtaW4iLCJkZXNjIjoiYWRtaW4gc3R1ZmYifV0sImF2YXRhcl91cmwiOiIvYXBpL2F1dGgvdXNlcnMvMS9hdmF0YXIifX0.53qx9kNdmzE09S79FbXarWUma3lIvyH1Ae8d_wq2o2M";
  const headers = {
    auth: {
      basic: {
        valid: {
          Authorization: `Basic ${btoa("zach:somepass")}`
        },
        invalid: {
          Authorization: `Basic ${btoa("zach:wrongpass")}`
        },
        bad_jwt: {
          Authorization: `Basic ${btoa("zach:special")}`
        }
      },
      bearer: {
        valid: {
          Authorization: `Bearer ${validJwt}`
        },
        invalid: {
          Authorization: "Bearer wrongToken"
        }
      }
    }
  };
  let User = null;
  let $httpBackend = null;
  let $http = null;
  // all the requisite modules must be instantiated
  // before asking to use components attached to them
  beforeEach(angular.mock.module("MagicStick"));
  beforeEach(
    angular.mock.inject(function($injector) {
      User = $injector.get("User");
      $httpBackend = $injector.get("$httpBackend");
      $http = $injector.get("$http");
      $httpBackend
        .whenPOST(
          "/api/auth/login",
          () => true,
          h => headers.auth.basic.bad_jwt.Authorization === h.Authorization
        ) // malformed token
        .respond(200, { token: "/-___--+===" });
      $httpBackend
        .whenPOST(
          "/api/auth/login",
          () => true,
          h =>
            headers.auth.basic.valid.Authorization !== h.Authorization &&
            headers.auth.bearer.valid.Authorization !== h.Authorization
        )
        .respond(401, { error: "Not authorized" });
      return $httpBackend
        .whenPOST(
          "/api/auth/login",
          () => true,
          h =>
            headers.auth.basic.valid.Authorization === h.Authorization ||
            headers.auth.bearer.valid.Authorization === h.Authorization
        )
        .respond(200, { token: btoa(validJwt) });
    })
  );
  afterEach(function() {
    $httpBackend.verifyNoOutstandingExpectation();
    return $httpBackend.verifyNoOutstandingRequest();
  });

  it("is initially logged out", function() {
    expect(User).toBeDefined();
    expect(User.token).toBeFalsy();
    expect(User.username).toEqual("");
    expect(User.roles).toEqual({});
    expect(User.loggedIn).toBeFalsy();
    return expect(
      $http.defaults.headers.common["Authorization"]
    ).toBeUndefined();
  });

  it("can log in", function() {
    expect(User).toBeDefined();
    User.login("zach", "somepass")
      .then(function() {
        expect(User.username).toEqual("zach");
        expect(User.loggedIn).toBeTruthy();
        expect(User.token).toEqual(validJwt);
        expect(User.roles).toEqual({ admin: true });
        return expect($http.defaults.headers.common["Authorization"]).toEqual(
          headers.auth.bearer.valid.Authorization
        );
      })
      .catch(function(e) {
        expect(e).toBeUndefined();
        return expect(true).toBeFalsy();
      }); // shouldn't have called here
    return $httpBackend.flush();
  });

  it("can handle an invalid login attempt", function() {
    User.logout();
    expect(User).toBeDefined();
    User.login("zach", "wrongpass")
      .then(function(res) {
        expect(res).toBeUndefined();
        return expect(true).toBeFalsy();
      })
      .catch(function(e) {
        expect(e).toBeDefined();
        expect(User.username).toEqual("");
        expect(User.token).toBeFalsy();
        expect(User.loggedIn).toBeFalsy();
        expect(User.roles).toEqual({});
        return expect(
          $http.defaults.headers.common["Authorization"]
        ).toBeUndefined();
      });
    return $httpBackend.flush();
  });

  it("can handle a bad token", function() {
    User.logout();
    expect(User).toBeDefined();
    expect(() =>
      User.login("zach", "special")
        .then(function(res) {
          expect(res).toBeUndefined();
          return expect(true).toBeFalsy();
        })
        .catch(function(e) {
          expect(e).toBeDefined();
          expect(User.username).toEqual("");
          expect(User.token).toBeFalsy();
          expect(User.loggedIn).toBeFalsy();
          expect(User.roles).toEqual({});
          return expect(
            $http.defaults.headers.common["Authorization"]
          ).toBeUndefined();
        })
    ).not.toThrow();
    return $httpBackend.flush();
  });

  return it("can log out", function() {
    expect(User).toBeDefined();
    User.login("zach", "somepass")
      .then(function() {
        User.logout();
        expect(User.token).toBeFalsy();
        expect(User.username).toEqual("");
        expect(User.loggedIn).toBeFalsy();
        expect(User.roles).toEqual({});
        return expect(
          $http.defaults.headers.common["Authorization"]
        ).toBeUndefined();
      })
      .catch(function(e) {
        expect(e).toBeUndefined();
        return expect(true).toBeFalsy();
      }); // shouldn't have called here
    return $httpBackend.flush();
  });
});
