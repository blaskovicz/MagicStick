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
      <p class="input-group" ng-switch-when="date">
        <input
          type="text"
          class="form-control"
          datepicker-popup="{{format}}"
          ng-model="dt"
          is-open="opened"
          datepicker-options="dateOptions"
          close-text="Close" />
        <span class="input-group-btn">
        <button
          type="button"
          class="btn btn-default"
          ng-click="open($event)">
          <i class="glyphicon glyphicon-calendar"></i>
        </button>
        </span>
      </p>
      <input
        class="form-control"
        id="{{label}}"
        type="text"
        ng-model="model"
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
