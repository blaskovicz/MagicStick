angular.module("MagicStick.directives").directive "formInput", ->
  scope:
    label: "@"
    type: "@"
    model: "="
    errorModel: "="
  restrict: "E"
  template: """
  <div class="form-group" ng-class="{'has-error': errorModel != null}">
    <label for="{{label}}" ng-bind="label"></label>
    <span ng-switch="type">
      <span ng-switch-when="date">
        <datepicker
          ng-model="$parent.model"
          >
        </datepicker>
        <timepicker
          ng-model="$parent.model"
          >
        </timepicker>
      </span>
      <input
        class="form-control"
        id="{{label}}"
        type="text"
        ng-model="$parent.model"
        ng-switch-default>
    </span>
    <span
      class="help-block"
      ng-if="errorModel != null"
      ng-bind="errorModel.join(', ')">
    </span>
  </div>
  """
  controller: [
    "$scope"
    ($scope) ->
      $scope.open = ($event) ->
        $event.preventDefault()
        $event.stopPropagation()
        $scope.opened = true
  ]
