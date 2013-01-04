options =
    appName: 'MyApp'

backend = require 'fp-backend'
backend.start options, (app) ->
    app.get "/", require './src/handlers/index'
