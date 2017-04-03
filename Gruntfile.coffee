_ = require 'lodash'
timegrunt = require 'time-grunt'
fs = require 'fs'
path = require 'path'
karmaFiles = JSON
                .parse(
                  fs.readFileSync(
                    path.join(__dirname, 'server', 'views', 'js.json')
                  ).toString()
                )
                .scripts
                .map((script) ->
                  "public/#{script}"
                )
karmaFiles
  .push(
    "public/bower_components/angular-mocks/angular-mocks.js"
    "public/js/app.js"
    "public/js/templates.js"
    "public/js/tests.js"
  )

module.exports = (grunt) ->
  timegrunt(grunt)
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    sass:
      app:
        files:
          'public/css/app.css': 'frontend/scss/app.scss'
    htmlhint:
      app:
        options:
          'tag-pair': true
          'id-unique': true
          'src-not-empty': true
        src: [
          'public/index.html'
          'frontend/views/**/*.html'
        ]
    html2js:
      options:
        module: 'MagicStick.templates'
        rename: (fileName) -> parts = fileName.split('/'); parts[parts.length - 1]
      templates:
        src: "frontend/views/**/*.html"
        dest: "public/js/templates.js"
    coffee:
      app:
        options:
          sourceMap: true
        files:
          'public/js/app.js': [
            'frontend/app.coffee'
            'frontend/filters/*.coffee'
            'frontend/services/*.coffee'
            'frontend/directives/*.coffee'
            'frontend/controllers/*.coffee'
            '!frontend/tests/**/*.coffee'
          ]
      tests:
        options:
          sourceMap: true
        files:
          'public/js/tests.js': [
            'frontend/tests/**/*.coffee'
          ]
    coffeelint:
      app: [
        'frontend/**/*.coffee'
        '!frontend/tests/**/*.coffee'
      ]
      tests: [
        'frontend/tests/**/*.coffee'
      ]
    karma:
      unit:
        options:
          frameworks: ['jasmine']
          singleRun: true
          browsers: ['PhantomJS']
          files: karmaFiles
          reporters: ['progress', 'coverage']
          preprocessors:
            'public/js/app.js': ['coverage']
            'public/js/templates.js': ['coverage']
          coverageReporter:
            reporters: [
              {
                type: 'json'
                subdir: '.' # ./coverage
                file: '.frontend.json'
              }
            ]
    watch:
      html:
        files: [
          'public/index.html'
          'frontend/views/**/*.html'
        ]
        tasks: [
          'htmlhint'
          'html2js'
        ]
      sass:
        files: 'frontend/scss/**/*.scss'
        tasks: 'sass'
      'coffee-app':
        files: [
          'frontend/**/*.coffee'
          '!frontend/tests/**/*.coffee'
        ]
        tasks: [
          'coffeelint:app'
          'coffee:app'
          'karma'
          'karma-simplecov-format'
        ]
      'coffee-tests':
        files: [
          'frontend/tests/**/*.coffee'
        ]
        tasks: [
          'coffeelint:tests'
          'coffee:tests'
          'karma'
        ]
      ruby:
        files: [
          '.rubocop*.yml'
          'app.rb'
          'db/**/*.rb'
          'server/**/*.rb'
          'server/tests/**/*.phantom.js'
          'server/views/js.json'
          'Rakefile'
          'config.ru'
        ]
        tasks: [
          'bgShell:pumaRestart'
          'bgShell:rake'
        ]
    bgShell:
      pumaRestart:
        cmd: 'touch tmp/restart.txt'
        fail: true
      rake:
        cmd: "rm -f #{__dirname}/test.db && bundle exec rake"
        fail: true
        execOpts:
          env: _.assign(_.cloneDeep(process.env),
            LOG_LEVEL: 'error'
            RACK_ENV: 'test'
            COVERALLS_NOISY: 'true'
          )
      shotgun:
        cmd: 'bundle exec puma config.ru -p 9393'
        bg: true
  grunt.registerTask 'karma-simplecov-format', 'transform karma coverage json into simplecov format', () ->
    coverInFile = path.join __dirname, 'coverage', '.frontend.json'
    coverOutFile = path.join __dirname, 'coverage', '.resultset.json'
    done = @async()
    coverOut = new Promise (resolve, reject) ->
      # https://github.com/colszowka/simplecov
      # { "Prog": { "coverage": { "file-path": [1,3,null,0] }, "timestamp": 1491185211 } }
      fs.readFile coverOutFile, 'utf8', (err, data) ->
        if err
          if err.code is 'ENOENT'
            resolve {}
          else
            reject(err)
        else
          resolve JSON.parse(data)
    coverIn = new Promise (resolve, reject) ->
      # https://github.com/gotwarlost/istanbul
      # { "file-path": { "path": "file-path", "l": {"1": 3, "4": 0 } }
      fs.readFile coverInFile, 'utf8', (err, data) ->
        if err
          reject(err)
        else
          covered = {}
          for file, coverage of JSON.parse(data)
            knownLines = _.keys(coverage.l).sort((a,b) -> +a - +b)
            lastLine = +knownLines[knownLines.length - 1] # 1-based index
            results = new Array(lastLine)
            for i in [0 .. lastLine - 1]
              results[i] = coverage.l[(+i)+1]
              if results[i] is undefined
                results[i] = null
            covered[file] = results
          resolve {
            Karma:
              timestamp: ((new Date()).getTime()/1000)
              coverage: covered
          }
    Promise.all([coverIn, coverOut])
      .then (results) ->
        simplecov = results[1]
        simplecov.Karma = results[0].Karma
        fs.writeFile coverOutFile, JSON.stringify(simplecov, null, ' '), (err) ->
          if err
            grunt.log.error("Failed to merge coverage info.")
            grunt.log.error(err)
            done(false)
          else
            grunt.log.writeln('Merged coverage info.')
            done()
      .catch (reason) ->
        grunt.log.error("Failed to discern coverage info.")
        grunt.log.error(reason)
        done(false)

  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-html2js'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-htmlhint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-bg-shell'
  grunt.registerTask 'build', ['htmlhint','html2js','sass','coffeelint','coffee']
  grunt.registerTask 'test', ['build', 'karma', 'karma-simplecov-format', 'bgShell:rake']
  grunt.registerTask 'dist', ['build']
  grunt.registerTask 'default', ['bgShell:shotgun','watch']
