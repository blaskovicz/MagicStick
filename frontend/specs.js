import "angular";
import "angular-mocks/angular-mocks";
import "./app";

// Include *.spec.js files
var context = require.context(".", true, /.+\.spec\.js$/);
context.keys().forEach(context);
