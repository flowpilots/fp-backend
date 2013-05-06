request = require 'superagent'
exec = require('child_process').exec
util = require 'util'

module.exports = (options) ->
    return (err, req, res, next) ->
        headers = req.headers
        delete headers.authorization if headers.authorization

        opts =
            cwd: __dirname + '/../../../'

        exec '/usr/bin/git rev-parse HEAD', opts, (e, stdout, stderr) ->
            version = stdout || e

            report =
                app: "node-#{options.appName}"
                version: "#{version.trim()} (Node #{process.version})"
                os: "#{process.platform} #{process.arg}"
                exception: err.stack || err
                env:
                    params: req.params
                    body: req.body
                    url: req.url
                    headers: headers
                    query: req.query

            request
                .post('http://crash.flowpilots.com/submit')
                .send(report)
                .end()

            next(err)
