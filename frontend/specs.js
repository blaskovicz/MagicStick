import "angular";
import "angular-mocks/angular-mocks";
import "./app";

// Include *.spec.js files
var context = require.context("./tests", true, /.+\.js$/);
context.keys().forEach(context);
