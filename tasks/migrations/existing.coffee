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
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  options =
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    'Accept-Language': 'en-US,en;q=0.8'
    'Cache-Control': 'max-age=0'
    'Accept-Charset': 'utf-8'
    'Content-Type': 'text/html; charset=utf-8'
    'Cookie': 'fastconnect=; ASP.NET_SessionId=jmohlxh2rrhepn5fowmvuclz'
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  request.head(url, options)
  .on 'response', (response) ->
    if [403, 404].indexOf(response.statusCode) isnt -1 then cb null, false
    else cb null, true
  .on 'error', (error) -> cb error

proceed_lot = (lot) ->
  new Promise (lot_resolve, lot_reject) ->
    exists lot.url, (err, lot_exists) ->
      lot_reject(err) if err?
      unless lot_exists
        console.log "Not exists lot #{lot.url}"
        mongo.lot_remove {url: lot.url, number: lot.number}, lot_resolve
      else lot_resolve()

module.exports = (grunt) ->
  grunt.registerTask 'migration:existing', ->
    done = @async()
    for etp in config.etps
      etps += "(#{etp.href.match(host)[2]})|"
    etps = etps.slice(0,-1)
    query =
      url: new RegExp(etps)
      status: $nin: valid
    finished = false
    proceed_range = (skip, cb) ->
      Lot.find(query).skip(skip).limit(50).exec (err, lots) ->
        cb(err) if err?
        console.log "Skip: #{skip}       Lots: #{lots.length}"
        if lots.length is 0 then cb()
        lot_promises = []
        for lot in lots
          lot_promises.push proceed_lot(lot)
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + 50, cb)
    proceed_range 0, done