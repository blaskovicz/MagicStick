angular.module("MagicStick.directives").directive "userView", ->
  restrict: "E"
  scope:
    "user": "&"
  templateUrl: "user.html"
