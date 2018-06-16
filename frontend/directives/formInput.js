/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";

angular.module("MagicStick.directives").directive("formInput", () => ({
  scope: {
    label: "@",
    type: "@",
    model: "=",
    options: "&",
    errorModel: "="
  },
  restrict: "E",
  template: `\
<div class="form-group" ng-class="{'has-error': errorModel != null}">
    <label for="{{label}}" ng-bind="label"></label>
    <span ng-switch="type">
      <span ng-switch-when="date">
        <div class="row">
          <div class="col-md-4">
            <datepicker ng-model="$parent.model">
            </datepicker>
          </div>
          <div class="col-md-2">
            <timepicker ng-model="$parent.model">
            </timepicker>
          </div>
        </div>
      </span>
      <span ng-switch-when="select">
        <select
          class="form-control"
          ng-options=
            "option.id as option.name for option in $parent.options()"
          ng-model="$parent.model">
        </select>
      </span>
      <input
        class="form-control"
        id="{{label}}"
        type="{{type}}"
        ng-model="$parent.model"
        ng-switch-default>
    </span>
    <span
      class="help-block"
      ng-if="errorModel != null"
      ng-bind="errorModel.join(', ')">
    </span>
</div>\
`,
  controller: [
    "$scope",
    $scope =>
      ($scope.open = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        return ($scope.opened = true);
      })
  ]
}));
