db = require './db'

SessionSchema = new db.Schema
    sid: { type: String, required: true, unique: true, index: true }
    data: db.Schema.Types.Mixed

Session = db.model('Session', SessionSchema)

class Store
    get: (sid, cb) ->
        Session.findOne { sid: sid }, (err, result) ->
            return cb(err) if err
            cb(null, result.data)

    set: (sid, session, cb) ->
        s =
            sid: sid
            data: session
        Session.update { sid: sid }, s, { upsert: true }, cb

    destroy: (sid, cb) ->
        Session.remove { sid: sid }, cb

module.exports = Store
