module.exports = (grunt) ->
  require('time-grunt')(grunt)
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
          #TODO this needs to be kept in sync almost 100%
          # with public/index.html scripts; we should find
          # a better way to do this (ie injecting them into that file)
          files: [
            "public/bower_components/jquery/dist/jquery.min.js"
            "public/bower_components/lodash/lodash.min.js"
            "public/bower_components/momentjs/min/moment.min.js"
            "public/bower_components/bootstrap/dist/js/bootstrap.min.js"
            "public/bower_components/angular/angular.min.js"
            "public/bower_components/angular-route/angular-route.min.js"
            "public/bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js"
            "public/bower_components/angular-toastr/dist/angular-toastr.tpls.js"
            "public/bower_components/angular-local-storage/dist/angular-local-storage.min.js"
            "public/bower_components/ng-file-upload/ng-file-upload.min.js"
            "public/bower_components/marked/marked.min.js"
            "public/bower_components/angular-marked/angular-marked.min.js"
            "public/bower_components/angular-mocks/angular-mocks.js"
            "public/js/app.js"
            "public/js/templates.js"
            "public/js/tests.js"
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
        cmd: 'bundle exec rake'
        fail: true
      shotgun:
        cmd: 'bundle exec puma config.ru -p 9393'
        bg: true
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-html2js'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-htmlhint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-bg-shell'
  grunt.registerTask 'build', ['htmlhint','html2js','sass','coffeelint','coffee']
  grunt.registerTask 'test', ['build','bgShell:rake','karma']
  grunt.registerTask 'dist', ['build']
  grunt.registerTask 'default', ['bgShell:shotgun','watch']
