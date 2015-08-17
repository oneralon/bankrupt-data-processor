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
            uniq.sync null, url
            console.log url
          done()
        catch e then done e

uniq = (url, cb) ->
  save = []
  turl = url.replace '://www.', ''
  rurl = new RegExp url.replace '://www.', '(://www.)?'
  Trade.find({url:rurl}).populate('lots').exec (err, trades) ->
    if trades.length is 1 then cb()
    else
      saved = trades[0]
      console.log "#{url} has dublicates"
      for trade in trades
        if trade._id isnt saved._id
          save.push new Promise (resolve) ->
            lots = []
            for lot in trade.lots
              lots.push new Promise (rs) -> lot.remove.then -> rs()
            Promise.all(lots).then -> trade.remove.then -> resolve()
      Promise.all(save).then -> cb()