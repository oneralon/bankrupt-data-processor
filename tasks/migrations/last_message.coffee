mongoose   = require 'mongoose'
Promise    = require 'promise'
config     = require '../../config'
mongo      = require '../../helpers/mongo'
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/lot'
Lot       = сonnection.model 'Lot'

module.exports = (grunt) ->
  grunt.registerTask 'migration:events', ->
    done = @async()
    etps = ''
    for etp in config.etps
      etps += "(#{etp.href.match(host)[2]})|"
    etps = etps.slice(0,-1)
    query = url: new RegExp(etps)
    perPage = 1000
    proceed_range = (skip, cb) ->
      Lot.find({last_event:{$or: [{$exists: false}, {$eq: null}, {$lte: new Date()}], present: true}).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        console.log "Skip: #{skip}       Lots: #{lots.length}"
        if lots.length is 0 then cb()
        lot_promises = []
        for lot in lots
          if lot.trade?
            if lot.intervals.length is 0
              lot.last_event = lot.trade.holding_date
              lot.present = new Date() < lot.last_event
              lot_promises.push new Promise (resolve) -> lot.save(resolve)
            else
              intervals = lot.intervals.filter (i) -> i.interval_start_date > new Date()
              if intervals.length > 0
                lot.last_event = intervals[0].interval_start_date
                lot.present = new Date() < lot.last_event
                lot_promises.push new Promise (resolve) -> lot.save(resolve)
              else
                lot.last_event = lot.intervals[lot.intervals.length - 1].interval_start_date
                lot.present = new Date() < lot.last_event
                lot_promises.push new Promise (resolve) -> lot.save(resolve)
          else
            console.log "Removing lot #{lot._id}"
            lot_promises.push new Promise (resolve) -> lot.remove(resolve)
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + perPage, cb)

    proceed_range 0, done