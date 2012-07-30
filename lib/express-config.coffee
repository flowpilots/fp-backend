express = require 'express'
stylus = require 'stylus'
nib = require 'nib'

clientJSCompile = require './client-compile'

dirToProject = __dirname + '/../../../'

# Needed for backbone.js
contentSwitch = () ->
    (req, res, next) ->
        if req.accepts 'application/json'
            req.format = 'json'
        next()

module.exports = (options, app) ->
    stylusOptions =
        src: dirToProject + '/src'
        dest: dirToProject + '/public'
        compile: (src, path) ->
            return stylus(src)
                .set('filename', path)
                .set('compress', true)
                .define('url', stylus.url(paths: [dirToProject + '/public/css/']))
                .use(nib())

    if options.trackSession
        SessionStore = require './sessions'
        sessionOptions =
            secret: 'Flying with Flow Pilots'
            store: new SessionStore()

    app.configure ->
        app.set 'views', dirToProject + '/src/views'
        app.set 'view engine', 'jade'
        if options.useLayout
            app.set 'view options', layout: dirToProject + '/src/views/_layout.jade'
        else
            app.set 'view options', layout: false
        app.set 'jsonp callback', true
        #app.use express.favicon(dirToProject + '/public/favicon.ico')
        app.use clientJSCompile(dirToProject, options.clientJSCompile) if options.useClientJSCompile
        app.use stylus.middleware(stylusOptions) if options.useStylus and app.settings.env == 'development'
        app.use express.logger(immediate: true)
        app.use express.static(dirToProject + '/public')
        app.use express.bodyParser()
        app.use express.cookieParser()
        app.use express.session sessionOptions if options.trackSession
        app.use express.methodOverride()
        app.use contentSwitch()

    app.configure 'development', ->
        app.use express.profiler()

    app.configure ->
        app.use app.router

    app.configure 'development', ->
        app.use express.errorHandler(
            dumpExceptions: true
            showStack: true
        )

    app.configure 'production', ->
        if options.useAutoQuit
            app.autoQuit({ timeOut: options.autoQuitTimeOut })
        app.use require('./crash-reporter')(options)
        app.use express.errorHandler()

    if options.allowCSR
        app.all "*", (req, res, next) ->
            res.header "Access-Control-Allow-Origin", "*"
            res.header "Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Authorization"
            next()
