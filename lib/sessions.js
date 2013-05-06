var ActiveSession, ActiveSessionSchema, Store, db, express, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

db = require('./index').db;

express = require('express');

ActiveSessionSchema = new db.Schema({
  sid: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  data: db.Schema.Types.Mixed
});

ActiveSession = db.model('ActiveSession', ActiveSessionSchema);

Store = (function(_super) {
  __extends(Store, _super);

  function Store() {
    _ref = Store.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Store.prototype.get = function(sid, cb) {
    return ActiveSession.findOne({
      sid: sid
    }, function(err, result) {
      if (err) {
        return cb(err);
      }
      return cb(null, result ? result.data : null);
    });
  };

  Store.prototype.set = function(sid, session, cb) {
    var s;

    s = {
      sid: sid,
      data: session
    };
    return ActiveSession.update({
      sid: sid
    }, s, {
      upsert: true
    }, function(err) {
      var cutOff, rand;

      cb(err);
      rand = Math.random();
      if (rand < 0.05) {
        cutOff = new Date();
        cutOff.setMonth(cutOff.getMonth() - 3);
        return ActiveSession.remove({
          'data.cookie.expires': {
            $lt: cutOff
          }
        }, function() {});
      }
    });
  };

  Store.prototype.destroy = function(sid, cb) {
    return ActiveSession.remove({
      sid: sid
    }, cb);
  };

  return Store;

})(express.session.Store);

module.exports = Store;
