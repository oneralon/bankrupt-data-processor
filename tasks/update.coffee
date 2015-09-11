mongoose   = require 'mongoose'
moment     = require 'moment'
Sync       = require 'sync'

amqp       = require '../helpers/amqp'
mongo      = require '../helpers/mongo'
valid      = Object.keys(require('../helpers/status').statuses)
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE UPDATER'
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/trade'
Trade     = сonnection.model 'Trade'
require '../models/lot'
Lot       = сonnection.model 'Lot'

module.exports = (grunt) ->
  grunt.registerTask 'update:invalid', ->
    log.info "Select for update invalid trades"
    done = @async()
    regex = ""
    for etp in config.etps
      regex += "(#{etp.href.match(host)[2]})|"
    regex = regex.slice(0,-1)
    query =
      url: new RegExp(regex)
      $or: [
        updated: { $exists: false }
      ,
        'etp.platform': { $exists: false }
      ]
    Trade.find query, (err, trades) ->
      done(err) if err?
      Sync =>
        try
          for trade in trades
            console.log trade.url
            etp = config.etps.filter( (t) ->
              r = new RegExp(trade.url.match(host)[2])
              r.test t.href
            )?[0]
            if etp?
              amqp.publish.sync null, config.tradeUrlsQueue, null, headers:
                etp: etp
                url: trade.url
                downloader: 'request'
                parser: "#{etp.platform}/trade"
                queue: config.tradeHtmlQueue
                number: trade.number
          log.info "Select for update invalid lots"
          query =
            url: new RegExp(regex)
            $or: [
              status: {$exists: true, $nin: valid}
            ,
              status: $exists: false
            ]
          Lot.distinct 'trade', query, (err, trade_ids) ->
            done(err) if err?
            Trade.find {_id: $in: trade_ids}, (err, trades) ->
              done(err) if err?
              Sync =>
                try
                  log.info "Found #{trades.length} trades"
                  for trade in trades
                    console.log trade.url
                    etp = config.etps.filter( (t) ->
                      r = new RegExp(trade.url.match(host)[2])
                      r.test t.href
                    )?[0]
                    if etp?
                      amqp.publish.sync null, config.tradeUrlsQueue, null, headers:
                        etp: etp
                        url: trade.url
                        downloader: 'request'
                        parser: "#{etp.platform}/trade"
                        queue: config.tradeHtmlQueue
                        number: trade.number
                  done()
                catch e then done(e)
        catch e then done(e)

  grunt.registerTask 'update:old', ->
    log.info "Select for update old trades"
    date = moment().subtract(2, 'day')
    query =
      updated: { $exists: true, $lt: date }
    done = @async()
    regex = ""
    for etp in config.etps
      regex += "#{etp.href.match(host)[2]}|"
    regex = regex.slice(0,-1)
    query.url = new RegExp(regex)
    Trade.find(query).limit(1000).exec (err, trades) ->
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

  grunt.registerTask 'update:meta', ->
    log.info 'Update meta info'
    done = @async()
    mongo.update_etps (err) ->
      done(err) if err?
      mongo.update_statuses (err) ->
        done(err) if err?
        mongo.update_regions (err) ->
          done(err) if err?
          done()
