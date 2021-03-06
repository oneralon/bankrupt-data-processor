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

getLots = (skip, cb) ->
  Lot.find($or:[{last_event: {$exists: false}}, {last_event:null}, {type:{$exists:false}}]).skip(skip).limit(1000).exec (err, lots) ->
    cb err if err?
    cb null, lots

proceed = (lots, cb) ->
  promises = []
  for lot in lots
    promises.push new Promise (resolve) ->
      uniq lot, resolve
  Promise.all(promises).then -> cb()

module.exports = (grunt) ->
  grunt.registerTask 'migration:dublicates', ->
    done = @async()
    skip = 0
    inProgress = true
    Sync =>
      try
        while inProgress
          lots = getLots.sync null, skip
          if lots.length is 0 then break
          console.log "Now: #{lots.length} \t\t\t Skip: #{skip}"
          proceed.sync null, lots
          console.log "Now: #{lots.length} \t\t\t Skip: #{skip} ------- OK"
          skip = skip + lots.length
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
        if i.status? and lot.status isnt '' then return 1
        return 2
      )[0]
      console.log "#{lot.url} has dublicates #{lots.length - 1}"
      for lot in lots
        if lot._id isnt saved._id
          saved.trade.lots = saved.trade.lots.filter (i) -> i.toString() isnt lot._id.toString()
          save.push new Promise (resolve) -> lot.remove(resolve)
      Promise.all(save).then ->
        saved.url = lurl
        saved.trade.save -> saved.save -> cb()
