db = require './db'
express = require 'express'

SessionSchema = new db.Schema
    sid: { type: String, required: true, unique: true, index: true }
    data: db.Schema.Types.Mixed

Session = db.model('Session', SessionSchema)

class Store extends express.session.Store
    get: (sid, cb) ->
        Session.findOne { sid: sid }, (err, result) ->
            return cb(err) if err
            cb(null, if result then result.data else null)

    set: (sid, session, cb) ->
        s =
            sid: sid
            data: session
        Session.update { sid: sid }, s, { upsert: true }, cb

    destroy: (sid, cb) ->
        Session.remove { sid: sid }, cb

module.exports = Store
