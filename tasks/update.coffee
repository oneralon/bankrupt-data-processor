mongoose   = require 'mongoose'
Sync        = require 'sync'

amqp       = require '../helpers/amqp'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE UPDATER'
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/trade'
Trade     = сonnection.model 'Trade'

module.exports = (grunt) ->
  grunt.registerTask 'update:invalid', ->
    log.info "Select for update invalid trades"
    query =
      updated: { $exists: false }
    done = @async()
    regex = ""
    for etp in config.etps
      regex += "#{etp.href.match(host)[2]}|"
    regex = regex.slice(0,-1)
    query.url = { $regex:regex }
    Trade.find().limit(100).exec (err, trades) ->
      done(err) if err?
      Sync =>
        try
          for trade in trades
            etp = config.etps.filter( (t) ->
              r = new RegExp(trade.url.match(host)[2])
              r.test t.href
            )?[0] 
            if etp?
              amqp.publish.sync null, config.tradeUrlsQueue, null, headers:
                etp: etp
                url: trade.url.replace '\/\/www.', '\/\/'
                downloader: 'request'
                parser: "#{etp.platform}/trade"
                queue: config.tradeHtmlQueue
                number: trade.number
          done()
        catch e then done(e)

