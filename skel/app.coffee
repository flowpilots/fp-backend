require.paths.unshift __dirname + '/src'

options =
    appName: 'MyApp'

backend = require 'fp-backend'
backend.start options, (app) ->
    app.get "/", require 'handlers/index'
