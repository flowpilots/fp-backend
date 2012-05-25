request = require 'superagent'

module.exports = (options) ->
    return (err, req, res, next) ->
        console.log err
        next(err)
