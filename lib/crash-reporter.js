var exec, request, util;

request = require('superagent');

exec = require('child_process').exec;

util = require('util');

module.exports = function(options) {
  return function(err, req, res, next) {
    var headers, opts;

    headers = req.headers;
    if (headers.authorization) {
      delete headers.authorization;
    }
    opts = {
      cwd: __dirname + '/../../../'
    };
    return exec('/usr/bin/git rev-parse HEAD', opts, function(e, stdout, stderr) {
      var report, version;

      version = stdout || e;
      report = {
        app: "node-" + options.appName,
        version: "" + (version.trim()) + " (Node " + process.version + ")",
        os: "" + process.platform + " " + process.arg,
        exception: err.stack || err,
        env: {
          params: req.params,
          body: req.body,
          url: req.url,
          headers: headers,
          query: req.query
        }
      };
      request.post('http://crash.flowpilots.com/submit').send(report).end();
      return next(err);
    });
  };
};
