express = require 'express'

# Needed for backbone.js
contentSwitch = () ->
    (req, res, next) ->
        if req.accepts 'application/json'
            req.format = 'json'
        next()

module.exports = (options, app) ->
    dirToProject = options.projectDir

    if options.trackSession
        SessionStore = require './sessions'
        sessionOptions =
            key: options.appName + ".sid"
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
        app.use express.logger(immediate: true)
        app.use express.static(dirToProject + '/public')
        app.use express.bodyParser()
        app.use express.cookieParser()
        app.use express.session sessionOptions if options.trackSession
        app.use express.methodOverride()
        app.use contentSwitch()

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
