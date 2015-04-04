angular.module("MagicStick.services").factory "User", [
  "$http"
  "$log"
  ($http, $log, toastr) ->
    new class User
      constructor: ->
        @loggedIn = false
        @username = ""
]
