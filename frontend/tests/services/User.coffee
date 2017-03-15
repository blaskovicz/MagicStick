describe "MagicStick.services.User", ->
  # coffeelint: disable=max_line_length
  # created with https://jwt.io/
  validJwt = \
  "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsImV4cCI6MTQ4OTI0Njg0OTAsImlzcyI6Im1hZ2ljLXN0aWNrIiwidXNlciI6eyJpZCI6MSwidXNlcm5hbWUiOiJ6YWNoIiwiZW1haWwiOiJlbWFpbEBtYWdpYy1zdGljay5oZXJva3VhcHAuY29tIiwiY2F0Y2hwaHJhc2UiOiJob3dzIGl0IGdvaW4nIGJyb3MiLCJjcmVhdGVkX2F0IjoiMjAxNS0wNC0xOCAxMDo1NDo1NSAtMDQwMCIsInVwZGF0ZWRfYXQiOiIyMDE3LTAzLTExIDA5OjQwOjMxIC0wNTAwIiwibGFzdF9sb2dpbiI6IjIwMTctMDMtMTEgMDk6NDA6MzEgLTA1MDAiLCJuYW1lIjoiWmFjaCBBdHRhY2siLCJhdmF0YXJfY29udGVudF90eXBlIjoiaW1hZ2UvanBlZyIsInJvbGVzIjpbeyJuYW1lIjoiYWRtaW4iLCJkZXNjIjoiYWRtaW4gc3R1ZmYifV0sImF2YXRhcl91cmwiOiIvYXBpL2F1dGgvdXNlcnMvMS9hdmF0YXIifX0.53qx9kNdmzE09S79FbXarWUma3lIvyH1Ae8d_wq2o2M"
  # coffeelint: enable=max_line_length
  headers =
    auth:
      basic:
        valid:
          Authorization: "Basic #{btoa('zach:somepass')}"
        invalid:
          Authorization: "Basic #{btoa('zach:wrongpass')}"
        bad_jwt:
          Authorization: "Basic #{btoa('zach:special')}"
      bearer:
        valid:
          Authorization: "Bearer #{validJwt}"
        invalid:
          Authorization: "Bearer wrongToken"
  User = null
  $httpBackend = null
  $http = null
  # all the requisite modules must be instantiated
  # before asking to use components attached to them
  beforeEach module "MagicStick"
  beforeEach inject ($injector) ->
    User = $injector.get "User"
    $httpBackend = $injector.get "$httpBackend"
    $http = $injector.get "$http"
    $httpBackend
      .whenPOST("/api/auth/login",
        () -> true,
        (h) ->
          headers.auth.basic.bad_jwt.Authorization is h.Authorization
      ) # malformed token
      .respond(200, { token: "/-___--+===" })
    $httpBackend
      .whenPOST("/api/auth/login",
        () -> true,
        (h) ->
          headers.auth.basic.valid.Authorization isnt h.Authorization &&\
          headers.auth.bearer.valid.Authorization isnt h.Authorization
      )
      .respond(401, {error: "Not authorized"})
    $httpBackend
      .whenPOST("/api/auth/login",
        () -> true,
        (h) ->
          headers.auth.basic.valid.Authorization is h.Authorization ||\
          headers.auth.bearer.valid.Authorization is h.Authorization
      )
      .respond(200, { token: btoa(validJwt) })
  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'is initially logged out', ->
    expect(User).toBeDefined()
    expect(User.token).toBeFalsy()
    expect(User.username).toEqual("")
    expect(User.roles).toEqual({})
    expect(User.loggedIn).toBeFalsy()
    expect($http.defaults.headers.common['Authorization']).toBeUndefined()

  it 'can log in', ->
    expect(User).toBeDefined()
    User.login("zach", "somepass")
      .then ->
        expect(User.username).toEqual("zach")
        expect(User.loggedIn).toBeTruthy()
        expect(User.token).toEqual(validJwt)
        expect(User.roles).toEqual({"admin":true})
        expect($http.defaults.headers.common['Authorization'])
          .toEqual(headers.auth.bearer.valid.Authorization)
      .catch (e)->
        expect(e).toBeUndefined()
        expect(true).toBeFalsy() # shouldn't have called here
    $httpBackend.flush()

  it 'can handle an invalid login attempt', ->
    User.logout()
    expect(User).toBeDefined()
    User.login("zach", "wrongpass")
      .then (res) ->
        expect(res).toBeUndefined()
        expect(true).toBeFalsy() # shouldn't have called here
      .catch (e)->
        expect(e).toBeDefined()
        expect(User.username).toEqual("")
        expect(User.token).toBeFalsy()
        expect(User.loggedIn).toBeFalsy()
        expect(User.roles).toEqual({})
        expect($http.defaults.headers.common['Authorization']).toBeUndefined()
    $httpBackend.flush()

  it 'can handle a bad token', ->
    User.logout()
    expect(User).toBeDefined()
    expect(->
      User.login("zach", "special")
        .then (res) ->
          expect(res).toBeUndefined()
          expect(true).toBeFalsy() # shouldn't have called here
        .catch (e)->
          expect(e).toBeDefined()
          expect(User.username).toEqual("")
          expect(User.token).toBeFalsy()
          expect(User.loggedIn).toBeFalsy()
          expect(User.roles).toEqual({})
          expect($http.defaults.headers.common['Authorization']).toBeUndefined()
    ).not.toThrow()
    $httpBackend.flush()

  it 'can log out', ->
    expect(User).toBeDefined()
    User.login("zach", "somepass")
      .then ->
        User.logout()
        expect(User.token).toBeFalsy()
        expect(User.username).toEqual("")
        expect(User.loggedIn).toBeFalsy()
        expect(User.roles).toEqual({})
        expect($http.defaults.headers.common['Authorization']).toBeUndefined()
      .catch (e)->
        expect(e).toBeUndefined()
        expect(true).toBeFalsy() # shouldn't have called here
    $httpBackend.flush()
