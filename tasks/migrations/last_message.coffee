mongoose   = require 'mongoose'
Promise    = require 'promise'
config     = require '../../config'
mongo      = require '../../helpers/mongo'
diffpatch  = require '../../helpers/diffpatch'
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/lot'
Lot       = сonnection.model 'Lot'

save = (container, item) ->
  container.push new Promise (resolve) -> 
    item.last_event = new Date(item.last_event)
    console.log item.url
    item.save()

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
        last_event: $exists: false
      ,
        last_event: null
      ]
    perPage = 1000
    proceed_range = (skip, cb) ->
      Lot.find(query).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        if not lots? or lots.length is 0 then cb()
        console.log "Skip: #{skip}       Lots: #{lots.length}"
        lot_promises = []
        for lot in lots
          console.log lot.last_event
          unless lot.trade? then lot_promises.push new Promise (resolve) -> lot.remove(resolve)
          else
            unless lot.trade._id? then lot_promises.push new Promise (resolve) -> lot.remove(resolve)
            else
              diffpatch.patch lot, diffpatch.diff(lot, diffpatch.intervalize(lot, lot.trade), Lot)
              save lot_promises, lot
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + perPage, cb)
    proceed_range 0, ->
      Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, done

  grunt.registerTask 'migration:present', ->
    console.log 'Update present field' 
    done = @async()
    Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, done
