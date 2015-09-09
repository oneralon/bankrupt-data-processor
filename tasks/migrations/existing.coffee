mongoose   = require 'mongoose'
Promise    = require 'promise'
request    = require 'request'
_          = require 'lodash'
config     = require '../../config'
mongo      = require '../../helpers/mongo'
valid      = Object.keys(require('../../helpers/status').statuses)
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/trade'
require '../../models/lot'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

regionize = require '../../helpers/regionize'

exists = (url, cb) ->
  options =
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    'Accept-Language': 'en-US,en;q=0.8'
    'Cache-Control': 'max-age=0'
    'Accept-Charset': 'utf-8'
    'Content-Type': 'text/html; charset=utf-8'
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  request.head(url, options)
  .on 'response', (response) ->
    if [400, 403, 404].indexOf(response.statusCode) isnt -1 then cb null, false
    else cb null, true
  .on 'error', (error) -> cb error

removeLot = (trade, lot, cb) ->
  console.log trade.lots
  console.log e
  cb()

module.exports = (grunt) ->
  grunt.registerTask 'migration:existing', ->
    done = @async()
    for etp in config.etps
      etps += "(#{etp.href.match(host)[2]})|"
    etps = etps.slice(0,-1)
    query =
      url: new RegExp(etps)
      status: $nin: valid
    Lot.distinct 'trade', query, (err, trade_ids) ->
      done(err) if err?
      Trade.find({_id: $in: trade_ids}).populate('lots').exec (err, trades) ->
        trade_promises = []
          for trade in trades
            trade_promises.push new Promise (trade_resolve) ->
              exists trade.url, (err, trade_exists) ->
                if trade_exists
                  lot_promises = []
                  for lot in trade.lots
                    lot_promises.push new Promise (lot_resolve) ->
                      exists lot.url, (err, lot_exists) ->
                        unless lot_exists
                          console.log "Not exists lot #{lot.url}"
                          # mongo.lot_remove {url: lot.url, number: lot.number}, lot_resolve
                          lot_resolve()
                        else lot_resolve()
                else
                  console.log "Not exists trade #{trade.url}"
                  # mongo.trade_remove trade.url, trade_resolve
                  trade_resolve()
        Promise.all(trade_promises).then -> done()