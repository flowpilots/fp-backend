module.exports = (grunt) ->
    @loadNpmTasks('grunt-contrib-clean')
    @loadNpmTasks('grunt-contrib-coffee')
    @loadNpmTasks('grunt-contrib-watch')
    @loadNpmTasks('grunt-release')

    @initConfig
        coffee:
            options:
                bare: true
            all:
                expand: true,
                cwd: 'src',
                src: ['*.coffee'],
                dest: 'lib',
                ext: '.js'

        clean:
            all: ['lib']

        watch:
            all:
                files: ['src/**.coffee']
                tasks: ['build']

        release:
            options:
                npm: false

    @registerTask 'default', ['build']
    @registerTask 'build', ['clean', 'coffee']
    @registerTask 'package', ['build', 'release']
