express = require 'express'
require 'express-resource'
path = require 'path'
http = require 'http'

defaultOptions =
    projectDir: path.normalize(__dirname + '/../../../')
    useSystemd: true
    useMonkeyPatches: true
    useClientJSCompile: true
    useLayout: false
    useAutoQuit: true
    autoQuitTimeOut: 600
    allowCSR: false
    trackSession: false
    standalonePort: 3000
    clientJSCompile:
        app:
            path: 'client-src'
            pack: []

config = {}

mergeOptions = (options, configure) ->
    # Options parameter is optional (configure too actually,
    # but that's unlikely)
    if !configure and typeof options == 'function'
        configure = options
        options = {}

    # Merge options
    options = {} if !options
    for key, val of defaultOptions
        options[key] = val if !options.hasOwnProperty(key)

    return [options, configure]

launchApp = (options, app) ->
    if options.useSystemd and process.env.LISTEN_PID > 0
        port = 'systemd'
    else if process.env.port
        port = process.env.port
    else
        port = options.standalonePort
    console.log "Listening (#{port})"
    server = http.createServer(app)
    if options.useAutoQuit && process.env.NODE_ENV == 'production'
        server.autoQuit({ timeOut: options.autoQuitTimeOut })
    server.listen(port)

start = (options, configure) ->
    [options, configure] = mergeOptions options, configure
    config = options

    # Connect to DB
    module.exports.db = createDb()

    # Optional modules
    require 'systemd' if options.useSystemd
    require 'mobile-monkeypatches' if options.useMonkeyPatches
    require 'autoquit' if options.useAutoQuit

    # Create app
    app = express()
    require('./express-config')(options, app)
    configure(app, express) if configure

    # Start server
    launchApp(options, app)

createDb = () ->
    db = process.env.MONGOLAB_URI || 'mongodb://localhost/' + (process.env.MONGO_DB || config.appName)

    mongoose = require 'mongoose'
    mongoose.connect db
    return mongoose

module.exports =
    start: start
