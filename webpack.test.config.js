const path = require("path");
const webpackConfig = require("./webpack.config");

Object.assign(webpackConfig, {
  entry: path.resolve(__dirname, "frontend", "specs.js"),
  devtool: "cheap-module-inline-source-map",
  output: {
    path: path.resolve(__dirname, "public"),
    filename: "specs.js"
  }
});

module.exports = webpackConfig;
