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
      console.log "#{url} has dublicates"
      i = 1
      while i < trades.length
        save.push new Promise (resolve) ->
          lots = []
          for lot in trades[i].lots
            lots.push new Promise (rs) -> lot.remove rs
          Promise.all(lots).then -> resolve()
        i++
      Promise.all(save).then -> cb()