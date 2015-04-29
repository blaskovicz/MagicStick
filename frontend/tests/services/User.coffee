describe "MagicStick.services.User", ->
  headers =
    auth:
      valid:
        Authorization: "Basic #{btoa('zach:somepass')}"
      invalid:
        Authorization: "Basic #{btoa('zach:wrongpass')}"
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
      .whenGET("/api/auth/me", (h) ->
        headers.auth.invalid.Authorization is h.Authorization
      )
      .respond(401, {error: "Not authorized"})
    $httpBackend
      .whenGET("/api/auth/me", (h) ->
        headers.auth.valid.Authorization is h.Authorization
      )
      .respond(200, {
        "username":"zach"
        "email":"zach@mail.com"
        "catchphrase":null
        "created_at":"2015-04-18 10:54:55 -0400"
        "updated_at":"2015-04-28 02:26:10 -0400"
        "last_login":"2015-04-28 02:26:10 -0400"
        "name":null
        "avatar_content_type":null
        "roles":[{name: 'admin', 'description': 'some desc'}]
        "avatar_url":"https://secure.gravatar.com/ava..."
      })
  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'is initially logged out', ->
    expect(User).toBeDefined()
    expect(User.username).toEqual("")
    expect(User.roles).toEqual({})
    expect(User.loggedIn).toBeFalsy()
    expect($http.defaults.headers.common['Authorization']).toBeUndefined()

  it 'can log in', ->
    User.login("zach", "somepass").then ->
      expect(User.username).toEqual("zach")
      expect(User.loggedIn).toBeTruthy()
      expect(User.roles).toEqual({"admin":true})
      expect($http.defaults.headers.common['Authorization'])
        .toEqual(headers.auth.valid.Authorization)
    $httpBackend.flush()

  it 'can handle an invalid login attempt', ->
    User.login("zach", "wrongpass").then ->
      expect(User.username).toEqual("")
      expect(User.loggedIn).toBeFalsy()
      expect(User.roles).toEqual({})
      expect($http.defaults.headers.common['Authorization']).toBeUndefined()
    $httpBackend.flush()

  it 'can log out', ->
    User.login("zach", "somepass").then ->
      User.logout()
      expect(User.username).toEqual("")
      expect(User.loggedIn).toBeFalsy()
      expect(User.roles).toEqual({})
      expect($http.defaults.headers.common['Authorization']).toBeUndefined()
    $httpBackend.flush()
