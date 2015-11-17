Sync       = require 'sync'
mongoose   = require 'mongoose'
config     = require '../../config'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"
require '../../models/trade'
Trade = сonnection.model 'Trade'

host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/

proceed = (cond, upd, cb) ->
  Trade.update cond, upd,  { multi: true }, cb

module.exports = (grunt) ->
  grunt.registerTask 'migration:etps-name', ->
    done = @async()
    Sync =>
      try
        for etp in config.etps
          res = etp.href.match(host)
          href = res[res.length - 1]
          regexp = new RegExp(href.replace('-', '\-').replace('.', '\.'), 'i')
          result = proceed.sync null, {url: regexp}, {$set: {'etp.name': etp.name, 'etp.href': etp.href, 'etp.url': etp.url}}
          console.log result
        done()
      catch e then done(e)
      