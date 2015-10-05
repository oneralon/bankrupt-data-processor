mongoose   = require 'mongoose'
Promise    = require 'promise'
config     = require '../../config'
mongo      = require '../../helpers/mongo'
diffpatch  = require '../../helpers/diffpatch'
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
          unless lot.trade._id? then lot_promises.push new Promise (resolve) -> lot.remove(resolve)
          else
            diffpatch lot, diffpatch.diff(diffpatch.intervalize(lot, trade), lot, Lot)
            lot_promises.push new Promise (resolve) -> lot.save(resolve)
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + perPage, cb)

    proceed_range 0, ->
      Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, done