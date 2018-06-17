const webpackConfig = require("./webpack.test.config");

module.exports = function(config) {
  config.set({
    basePath: ".",
    frameworks: ["jasmine"],

    reporters: ["mocha", "coverage"],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ["PhantomJS"],
    singleRun: true,
    autoWatchBatchDelay: 300,

    files: ["public/specs.js"],

    preprocessors: {
      "specs.js": ["webpack", "sourcemap", "coverage"]
    },

    webpack: webpackConfig,

    webpackMiddleware: {
      stats: "minimal"
    },

    coverageReporter: {
      dir: "coverage",
      reporters: [
        {
          type: "json",
          subdir: ".", // ./coverage
          file: ".frontend.json"
        }
      ],
      instrumenterOptions: {
        istanbul: { noCompact: true }
      }
    }
  });
};
