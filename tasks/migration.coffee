Sync       = require 'sync'
Promise    = require 'promise'
mongoose   = require 'mongoose'

config     = require '../config'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/trade'
require '../models/lot'
require '../models/tag'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

module.exports = (grunt) ->
  grunt.registerTask 'migration:dublicates', ->
    done = @async()
    Trade.distinct('url').exec (err, urls) ->
      Sync =>
        try
          for url in urls
            console.log "#{urls.indexOf(url)}/#{urls.length}"
            uniq.sync null, url
          done()
        catch e then done e

uniq = (url, cb) ->
  save = []
  turl = url.replace '://www.', '://'
  rurl = new RegExp turl.replace '://', '://(www.)?'
  Trade.find({url:rurl}).populate('lots').exec (err, trades) ->
    if trades.length is 1 then cb()
    else
      saved = trades[0]
      console.log "#{url} has dublicates #{trades.length}"
      for trade in trades
        if trade._id isnt saved._id
          save.push new Promise (resolve) -> remove(trade, resolve)
      Promise.all(save).then ->
        saved.url = turl
        saved.save(cb)

remove = (trade, cb) ->
  lots = []
  for lot in trade.lots
    lots.push new Promise (resolve) -> lot.remove(resolve)
  Promise.all(lots).then -> trade.remove(cb)
