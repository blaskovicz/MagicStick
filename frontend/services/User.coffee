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
      loadFromStorage: ->
        user = localStorageService.get('currentUser')
        return unless user?
        @username = user.username if user.username?
        @authHeader = user.authHeader if user.authHeader? and @username?
        if @authHeader?
          $http.defaults.headers.common['Authorization'] = @authHeader
          @loggedIn = true
          @loadPrincipal()
          @broadcastLoginStateChange()
      login: (username, password) ->
        promise = $q.defer()
        unless password? and username?
          promise.reject("Insufficient credentials provided")
          return promise.promise
        authHeader =
          "Basic #{btoa(username + ':' + password)}"
        $http.get("/api/auth/me", { headers: {Authorization: authHeader} })
          .success (data, status, headers) =>
            $http.defaults.headers.common['Authorization'] =
              @authHeader = authHeader
            @loggedIn = true
            @username = username
            @parsePrincipal(data)
            @saveToStorage()
            @broadcastLoginStateChange()
            promise.resolve()
          .error (data, status, headers) ->
            promise.reject(data?.errors ? "Invalid credentials")
        promise.promise
      loadPrincipal: ->
        $http.get("/api/auth/me")
          .success (data) =>
            @parsePrincipal(data)
      parsePrincipal: (data) ->
        return unless data?
        @roles = {}
        for role in data.roles
          @roles[role.name] = true
      logout: ->
        @loggedIn = false
        @username = ""
        @roles = {}
        delete $http.defaults.headers.common['Authorization']
        localStorageService.set('currentUser', null)
        @broadcastLoginStateChange()
        $location.path("/")
      saveToStorage: ->
        localStorageService.set('currentUser', @)
      broadcastLoginStateChange: ->
        $rootScope.$broadcast("currentUser:login:changed")

]
