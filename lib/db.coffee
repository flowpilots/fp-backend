backend = require './backend'

config = backend.config()

db = process.env.MONGOLAB_URI || 'mongodb://localhost/' + config.appName

mongoose = require 'mongoose'
mongoose.connect db
module.exports = mongoose
