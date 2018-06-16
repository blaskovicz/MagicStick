/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const _ = require("lodash");
const Promise = require("es6-promise");
const timegrunt = require("time-grunt");
const fs = require("fs");
const path = require("path");
const webpackConfig = require("./webpack.config");
const webpackTestConfig = require("./webpack.test.config");

module.exports = function(grunt) {
  timegrunt(grunt);
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    htmlhint: {
      app: {
        options: {
          "tag-pair": true,
          "id-unique": true,
          "src-not-empty": true
        },
        src: ["public/index.html", "frontend/views/**/*.html"]
      }
    },
    webpack: {
      keepalive: false,
      options: {
        stats: (process.env.WEBPACK_ENV || "development") === "development"
      },
      app: webpackConfig,
      test: webpackTestConfig
    },
    eslint: {
      app: ["frontend/**/*.js", "!frontend/tests/**/*.js"],
      tests: ["frontend/tests/**/*.js"]
    },
    karma: {
      unit: {
        options: {
          frameworks: ["jasmine"],
          singleRun: true,
          browsers: ["PhantomJS"],
          files: ["public/styles.specs.js", "public/specs.js"],
          reporters: ["progress", "coverage"],
          preprocessors: {
            "public/specs.js": ["coverage"]
          },
          coverageReporter: {
            reporters: [
              {
                type: "json",
                subdir: ".", // ./coverage
                file: ".frontend.json"
              }
            ]
          }
        }
      }
    },
    watch: {
      html: {
        files: ["public/index.html", "frontend/views/**/*.html"],
        tasks: ["htmlhint", "webpack:app"]
      },
      js: {
        files: ["frontend/**/*.js", "!frontend/tests/**/*.js"],
        tasks: ["eslint:app", "webpack:app", "karma", "karma-simplecov-format"]
      },
      sass: {
        files: "frontend/scss/**/*.scss",
        tasks: "sass"
      },
      "js-tests": {
        files: ["frontend/tests/**/*.js"],
        tasks: ["eslint:tests", "js:tests", "karma"]
      },
      ruby: {
        files: [
          ".rubocop*.yml",
          "app.rb",
          "db/**/*.rb",
          "server/**/*.rb",
          "server/tests/**/*.phantom.js",
          "server/views/js.json",
          "Rakefile",
          "config.ru"
        ],
        tasks: ["bgShell:pumaRestart", "bgShell:rake"]
      }
    },
    bgShell: {
      pumaRestart: {
        cmd: "touch tmp/restart.txt",
        fail: true
      },
      rake: {
        cmd: `rm -f ${__dirname}/test.db && bundle exec rake`,
        fail: true,
        execOpts: {
          env: _.assign(_.cloneDeep(process.env), {
            LOG_LEVEL: "error",
            RACK_ENV: "test",
            COVERALLS_NOISY: "true"
          })
        }
      },
      shotgun: {
        cmd: `bundle exec puma config.ru -p ${process.env.PORT || 3001}`,
        bg: true
      }
    }
  });
  grunt.registerTask(
    "karma-simplecov-format",
    "transform karma coverage json into simplecov format",
    function() {
      const coverInFile = path.join(__dirname, "coverage", ".frontend.json");
      const coverOutFile = path.join(__dirname, "coverage", ".resultset.json");
      const done = this.async();
      const coverOut = new Promise(function(resolve, reject) {
        // https://github.com/colszowka/simplecov
        // { "Prog": { "coverage": { "file-path": [1,3,null,0] }, "timestamp": 1491185211 } }
        return fs.readFile(coverOutFile, "utf8", function(err, data) {
          if (err) {
            if (err.code === "ENOENT") {
              return resolve({});
            } else {
              return reject(err);
            }
          } else {
            return resolve(JSON.parse(data));
          }
        });
      });
      const coverIn = new Promise(function(resolve, reject) {
        // https://github.com/gotwarlost/istanbul
        // { "file-path": { "path": "file-path", "l": {"1": 3, "4": 0 } }
        return fs.readFile(coverInFile, "utf8", function(err, data) {
          if (err) {
            return reject(err);
          } else {
            let coverage;
            const covered = {};
            const object = JSON.parse(data);
            for (let file in object) {
              coverage = object[file];
              const knownLines = _.keys(coverage.l).sort((a, b) => +a - +b);
              const lastLine = +knownLines[knownLines.length - 1]; // 1-based index
              const results = new Array(lastLine);
              for (
                let i = 0, end = lastLine - 1, asc = 0 <= end;
                asc ? i <= end : i >= end;
                asc ? i++ : i--
              ) {
                results[i] = coverage.l[+i + 1];
                if (results[i] === undefined) {
                  results[i] = null;
                }
              }
              covered[file] = results;
            }
            return resolve({
              Karma: {
                timestamp: new Date().getTime() / 1000,
                coverage: covered
              }
            });
          }
        });
      });
      return Promise.all([coverIn, coverOut])
        .then(function(results) {
          const simplecov = results[1];
          simplecov.Karma = results[0].Karma;
          return fs.writeFile(
            coverOutFile,
            JSON.stringify(simplecov, null, " "),
            function(err) {
              if (err) {
                grunt.log.error("Failed to merge coverage info.");
                grunt.log.error(err);
                return done(false);
              } else {
                grunt.log.writeln("Merged coverage info.");
                return done();
              }
            }
          );
        })
        .catch(function(reason) {
          grunt.log.error("Failed to discern coverage info.");
          grunt.log.error(reason);
          return done(false);
        });
    }
  );

  grunt.loadNpmTasks("grunt-karma");
  grunt.loadNpmTasks("grunt-eslint");
  grunt.loadNpmTasks("grunt-contrib-watch");
  grunt.loadNpmTasks("grunt-htmlhint");
  grunt.loadNpmTasks("grunt-bg-shell");
  grunt.loadNpmTasks("grunt-webpack");
  grunt.registerTask("build", [
    "htmlhint",
    "eslint",
    "webpack:app",
    "webpack:test"
  ]);
  grunt.registerTask("test", [
    "build",
    "karma",
    "karma-simplecov-format",
    "bgShell:rake"
  ]);
  grunt.registerTask("dist", ["build"]);
  return grunt.registerTask("default", ["bgShell:shotgun", "watch"]);
};
