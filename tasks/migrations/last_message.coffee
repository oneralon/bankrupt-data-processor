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
    query =
      url: new RegExp(etps)
      $or: [
        present: true, last_date: $lte: new Date()
      ,
        present: $exists: false
      , 
        last_date: $exists: false
      ]
    perPage = 1000
    proceed_range = (skip, cb) ->
      Lot.find(query).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        if not lots? or lots.length is 0 then cb()
        console.log "Skip: #{skip}       Lots: #{lots.length}"
        lot_promises = []
        for lot in lots
          unless lot.trade._id? then lot_promises.push new Promise (resolve) -> lot.remove(resolve)
          else
            diffpatch.patch lot, diffpatch.diff(lot, diffpatch.intervalize(lot, lot.trade), Lot)
            lot_promises.push new Promise (resolve) -> lot.save(resolve)
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + perPage, cb)
    proceed_range 0, ->
      Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, done