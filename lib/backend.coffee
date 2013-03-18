express = require 'express'
require 'express-resource'

defaultOptions =
    useSystemd: true
    useMonkeyPatches: true
    useClientJSCompile: true
    useStylus: true
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
        options[key] = val if !options[key]

    return [options, configure]

launchApp = (options, app) ->
    if options.useSystemd and process.env.LISTEN_PID > 0
        port = 'systemd'
    else if process.env.port
        port = process.env.port
    else
        port = options.standalonePort
    console.log "Listening (#{port})"
    app.listen port

start = (options, configure) ->
    [options, configure] = mergeOptions options, configure
    config = options

    # Optional modules
    require 'systemd' if options.useSystemd
    require 'mobile-monkeypatches' if options.useMonkeyPatches
    require 'autoquit' if options.useAutoQuit

    # Create app
    app = module.exports = express.createServer()
    require('./express-config')(options, app)
    configure(app, express) if configure

    # Start server
    launchApp(options, app)

module.exports =
    start: start
    config: () -> config # hack needed to prevent circular refs
