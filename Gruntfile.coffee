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
            '!frontend/**/*.test.coffee'
          ]
    coffeelint:
      app: [
        'frontend/**/*.coffee'
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
      coffee:
        files: 'frontend/**/*.coffee'
        tasks: [
          'coffeelint'
          'coffee'
        ]
      ruby:
        files: [
          'server/**/*.rb'
          'spec/**/*.rb'
          'Rakefile'
          'config.ru'
        ]
        tasks: [
          'bgShell:rake'
        ]
    bgShell:
      rake:
        cmd: 'bundler exec rake'
        fail: true
      shotgun:
        cmd: 'bundler exec shotgun config.ru'
        bg: true
  grunt.loadNpmTasks 'grunt-html2js'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-htmlhint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-bg-shell'
  grunt.registerTask 'build', ['htmlhint','html2js','sass','coffeelint','coffee','bgShell:rake']
  grunt.registerTask 'dist', ['build']
  grunt.registerTask 'default', ['build','bgShell:shotgun','watch']
