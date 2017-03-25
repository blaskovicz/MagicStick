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
            LOG_LEVEL: 'warn'
            RACK_ENV: 'test'
          )
      shotgun:
        cmd: 'bundle exec puma config.ru -p 9393'
        bg: true
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-html2js'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-htmlhint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-bg-shell'
  grunt.registerTask 'build', ['htmlhint','html2js','sass','coffeelint','coffee']
  grunt.registerTask 'test', ['build','bgShell:rake','karma']
  grunt.registerTask 'dist', ['build']
  grunt.registerTask 'default', ['bgShell:shotgun','watch']
