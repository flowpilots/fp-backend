backend = require 'fp-backend'

config = backend.config()

db = process.env.MONGOLAB_URI || 'mongodb://localhost/' + (process.env.MONGO_DB || config.appName)

mongoose = require 'mongoose'
mongoose.connect db
module.exports = mongoose
