var config, createDb, defaultOptions, express, http, launchApp, mergeOptions, path, start;

express = require('express');

require('express-resource');

path = require('path');

http = require('http');

defaultOptions = {
  projectDir: path.normalize(__dirname + '/../../../'),
  useSystemd: true,
  useMonkeyPatches: true,
  useClientJSCompile: true,
  useLayout: false,
  useAutoQuit: true,
  autoQuitTimeOut: 600,
  allowCSR: false,
  trackSession: false,
  standalonePort: 3000,
  clientJSCompile: {
    app: {
      path: 'client-src',
      pack: []
    }
  }
};

config = {};

mergeOptions = function(options, configure) {
  var key, val;

  if (!configure && typeof options === 'function') {
    configure = options;
    options = {};
  }
  if (!options) {
    options = {};
  }
  for (key in defaultOptions) {
    val = defaultOptions[key];
    if (!options[key]) {
      options[key] = val;
    }
  }
  return [options, configure];
};

launchApp = function(options, app) {
  var port, server;

  if (options.useSystemd && process.env.LISTEN_PID > 0) {
    port = 'systemd';
  } else if (process.env.port) {
    port = process.env.port;
  } else {
    port = options.standalonePort;
  }
  console.log("Listening (" + port + ")");
  server = http.createServer(app);
  if (options.useAutoQuit && process.env.NODE_ENV === 'production') {
    server.autoQuit({
      timeOut: options.autoQuitTimeOut
    });
  }
  return server.listen(port);
};

start = function(options, configure) {
  var app, _ref;

  _ref = mergeOptions(options, configure), options = _ref[0], configure = _ref[1];
  config = options;
  module.exports.db = createDb();
  if (options.useSystemd) {
    require('systemd');
  }
  if (options.useMonkeyPatches) {
    require('mobile-monkeypatches');
  }
  if (options.useAutoQuit) {
    require('autoquit');
  }
  app = express();
  require('./express-config')(options, app);
  if (configure) {
    configure(app, express);
  }
  return launchApp(options, app);
};

createDb = function() {
  var db, mongoose;

  db = process.env.MONGOLAB_URI || 'mongodb://localhost/' + (process.env.MONGO_DB || config.appName);
  mongoose = require('mongoose');
  mongoose.connect(db);
  return mongoose;
};

module.exports = {
  start: start
};
