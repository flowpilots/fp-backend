var contentSwitch, express;

express = require('express');

contentSwitch = function() {
  return function(req, res, next) {
    if (req.accepts('application/json')) {
      req.format = 'json';
    }
    return next();
  };
};

module.exports = function(options, app) {
  var SessionStore, dirToProject, sessionOptions;

  dirToProject = options.projectDir;
  if (options.trackSession) {
    SessionStore = require('./sessions');
    sessionOptions = {
      key: options.appName + ".sid",
      secret: 'Flying with Flow Pilots',
      store: new SessionStore()
    };
  }
  app.configure(function() {
    app.set('views', dirToProject + '/src/views');
    app.set('view engine', 'jade');
    if (options.useLayout) {
      app.set('view options', {
        layout: dirToProject + '/src/views/_layout.jade'
      });
    } else {
      app.set('view options', {
        layout: false
      });
    }
    app.set('jsonp callback', true);
    app.set('trust proxy', true);
    app.use(express.logger({
      immediate: true
    }));
    app.use(express["static"](dirToProject + '/public'));
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    if (options.trackSession) {
      app.use(express.session(sessionOptions));
    }
    app.use(express.methodOverride());
    return app.use(contentSwitch());
  });
  app.configure(function() {
    return app.use(app.router);
  });
  app.configure('development', function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });
  app.configure('production', function() {
    app.use(require('./crash-reporter')(options));
    return app.use(express.errorHandler());
  });
  if (options.allowCSR) {
    return app.all("*", function(req, res, next) {
      res.header("Access-Control-Allow-Origin", "*");
      res.header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Authorization");
      return next();
    });
  }
};
