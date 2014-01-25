'use strict'

module.exports = (grunt)->
    # load all grunt tasks
    (require 'matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

    _ = grunt.util._
    path = require 'path'

    # Project configuration.
    grunt.initConfig { # <-- Per helpful-convention, require braces around long blocks
    
        pkg: grunt.file.readJSON('package.json')

        coffeelint:
            gruntfile: ['<%= watch.gruntfile.files %>']
            src: ['<%= watch.src.files %>']
            options:
                configFile: "coffeelint.json"

        coffee:
            src:
                expand: true
                cwd: 'src/'
                src: ['**/*.coffee']
                dest: 'out/'
                ext: '.js'

        watch:
            options:
                spawn: true
            gruntfile:
                files: 'Gruntfile.coffee'
                tasks: ['coffeelint:gruntfile']
            src:
                files: ['src/**/*.coffee']
                tasks: ['coffeelint:src', 'coffee:src', 'example:respawn']

        clean: ['out/']

        nodemon:
            dev:
                script: 'src/example/example.coffee'
                watch: ['src']
                delayTime: 1000 # 1 second
                ext: 'js,coffee'
            dev2:
                watch: ['src']
                delayTime: 1000 # 1 second
                ext: 'js,coffee'
                exec: 'coffee'
                args: ['src/example/example.coffee', '-n']

        concurrent:
            dev:
                tasks: ['nodemon:dev', 'watch']
                options:
                    logConcurrentOutput: true
    
    } # <-- Per helpful-convention, require braces around long blocks

    grunt.event.on 'watch', (action, files, target)->
        grunt.log.writeln "#{target}: #{files} has #{action}"

        # coffeelint
        grunt.config ['coffeelint', target], src: files

        # coffee
        if target != 'gruntfile'
            coffeeData = grunt.config ['coffee', target]
            files = [files] if _.isString files
            files = files.map (file)-> path.relative coffeeData.cwd, file
            coffeeData.src = files
            grunt.config ['coffee', target], coffeeData

    # tasks.
    grunt.registerTask 'compile', ['coffeelint', 'coffee']
    grunt.registerTask 'default', ['compile']
    # grunt.registerTask 'dev', ['compile', 'concurrent:dev']
    # grunt.registerTask 'dev', ['compile', 'nodemon:dev2']

    [child,childKilled,shouldSpawn] = [false,false,false]


    grunt.registerTask 'example', 'Run Example', ->
        shouldSpawn = true
        grunt.task.run 'example:respawn', 'watch'

    grunt.registerTask 'example:respawn', '[internal]', ->
        if child
            grunt.log.writeln "Killing child!"
            childKilled = true
            child.kill()
        if shouldSpawn
            grunt.log.writeln "Spawning child!"
            child = require('child_process').fork(grunt.config 'nodemon.dev.script')
            child.on 'exit', (code) ->
                if !childKilled
                    process.exit code
                else
                    childKilled = false # reset and ignore for now
