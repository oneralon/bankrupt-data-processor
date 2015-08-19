mongoose   = require 'mongoose'
Promise    = require 'promise'
config     = require '../../config'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/trade'
require '../../models/lot'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

regionize = require '../../helpers/regionize'

module.exports = (grunt) ->
  grunt.registerTask 'migration:regions', ->
    done = @async()
    save = []
    stream = Trade.find().stream()
    stream.on 'data', (trade) ->
      save.push new Promise (resolve) ->
        trade.region = regionize trade
        Lot.find {trade: trade}, (err, lots) ->
          done err if err?
          save_lots = []
          for lot in lots
            save_lots.push new Promise (rsv) ->
              lot.region = trade.region
              lot.save(rsv)
          Promise.all(save_lots).then ->
            console.log "Save trade #{trade.url}"
            trade.save(resolve)
    stream.on 'end', ->
      Promise.all(save).then done
    stream.on 'error', (err) ->
      done err if err?