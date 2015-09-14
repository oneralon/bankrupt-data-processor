Promise    = require 'promise'
Sync       = require 'sync'
mongoose   = require 'mongoose'
_          = require 'lodash'

config     = require '../../config'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/trade'
require '../../models/lot'
require '../../models/tag'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

module.exports = (grunt) ->
  grunt.registerTask 'migration:dublicates', ->
    done = @async()
    Lot.find({updated: {$exists: false}}).limit(5000).exec (err, lots) ->
      Sync =>
        try
          for lot in lots
            console.log "#{lots.indexOf(url)}/#{lots.length}"
            uniq.sync null, lot
          done()
        catch e then done e

uniq = (lot, cb) ->
  save = []
  lurl = lot.url.replace '://www.', '://'
  rurl = new RegExp lurl.replace '://', '://(www.)?'
  Lot.find({url:rurl, number: lot.number}).populate('trade').exec (err, lots) ->
    if lots.length < 2 then cb()
    else
      saved = _.sortBy(lots, (i) ->
        if i.updated? then return 0
        if i.status? and status isnt '' then return 1
        return 2
      )[0]
      console.log "#{lot.url} has dublicates #{lots.length - 1}"
      for lot in lots
        if lot._id isnt saved._id
          saved.trade.lots = saved.trade.lots.filter (i) -> i._id.toString() isnt lot._id.toString()
          save.push new Promise (resolve) -> lot.remove(resolve)
      Promise.all(save).then ->
        saved.url = lurl
        saved.trade.save -> saved.save(cb)