db = require('./backend').db
express = require 'express'

ActiveSessionSchema = new db.Schema
    sid: { type: String, required: true, unique: true, index: true }
    data: db.Schema.Types.Mixed

ActiveSession = db.model('ActiveSession', ActiveSessionSchema)

class Store extends express.session.Store
    get: (sid, cb) ->
        ActiveSession.findOne { sid: sid }, (err, result) ->
            return cb(err) if err
            cb(null, if result then result.data else null)

    set: (sid, session, cb) ->
        s =
            sid: sid
            data: session
        ActiveSession.update { sid: sid }, s, { upsert: true }, cb

    destroy: (sid, cb) ->
        ActiveSession.remove { sid: sid }, cb

module.exports = Store
