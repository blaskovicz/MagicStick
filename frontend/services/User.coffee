angular.module("MagicStick.services").factory "User", [
  "$http"
  "$log"
  "$q"
  "localStorageService"
  "$rootScope"
  "$location"
  ($http, $log, $q, localStorageService, $rootScope, $location) ->
    new class User
      constructor: ->
        @loggedIn = false
        @username = ""
        @roles = {}
        $rootScope.$on "currentUser:login:force_logout", =>
          $log.info "performing logout"
          @logout()
      clone: ->
        {
          @username
          @id
          @name
          @token
          @exp
          @catchphrase
          @avatar_url
        }
      parseToken: ->
        return unless @token?
        jwt_decode(@token)
      loadFromStorage: ->
        user = localStorageService.get('currentUser')
        return unless user?
        @token = user.token if user.token?
        @exp = user.exp if user.exp?
        @username = user.username if user.username?
        @authHeader = user.authHeader if user.authHeader?
        unless @token?
          @logout(true)
          return
        $http.defaults.headers.common['Authorization'] = @authHeader
        try
          @parsePrincipal(@parseToken()?.user)
          @loggedIn = true
          @broadcastLoginStateChange()
        catch
          @logout(true)
      login: (username, password) ->
        promise = $q.defer()
        unless password? and username?
          promise.reject("Insufficient credentials provided")
          return promise.promise
        authHeader =
          "Basic #{btoa(username + ':' + password)}"
        $http.post("/api/auth/login", '',
          { headers: {Authorization: authHeader} })
          .success (data, status, headers) =>
            # header.payload.sig
            try
              @token = base64_url_decode(data.token)
              payload = @parseToken()
            catch e
              @token = null
              promise.reject("failed to log in")
              return
            @exp = payload.exp
            $http.defaults.headers.common['Authorization'] =
              @authHeader = "Bearer #{@token}"
            @loggedIn = true
            @parsePrincipal(payload.user)
            @saveToStorage()
            @broadcastLoginStateChange()
            promise.resolve()
          .error (data, status, headers) ->
            promise.reject(data?.errors ? "Invalid credentials")
        promise.promise
      slackInfo: ->
        $http.get("/api/auth/me/slack")
      get: ->
        $http.get("/api/auth/me")
      loadPrincipal: ->
        @get()
          .success (data) =>
            @parsePrincipal(data)
          .error (data, status, headers) =>
            $log.warn("Couldn't load auth data: #{data}")
            @logout() if status is 401
      parsePrincipal: (data) ->
        return unless data?
        @id = data.id
        @name = data.name
        @username = data.username
        @avatar_url = data.avatar_url
        @catchphrase = data.catchphrase
        @roles = {}
        for role in data.roles
          @roles[role.name] = true
      logout: (quiet = false) ->
        @id = null
        @token = null
        @exp = null
        @loggedIn = false
        @name = ""
        @catchphrase = ""
        @username = ""
        @roles = {}
        @avatar_url = null
        delete $http.defaults.headers.common['Authorization']
        localStorageService.set('currentUser', null)
        return if quiet
        @broadcastLoginStateChange()
        $location.path("/")
      saveToStorage: ->
        localStorageService.set('currentUser', @)
      broadcastLoginStateChange: ->
        $rootScope.$broadcast("currentUser:login:changed")
]
