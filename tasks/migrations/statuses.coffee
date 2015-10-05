mongoose   = require 'mongoose'
Promise    = require 'promise'
config     = require '../../config'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../../models/trade'
require '../../models/lot'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

status = require '../../helpers/status'

module.exports = (grunt) ->
  grunt.registerTask 'migration:statuses', ->
    done = @async()
    keys = Object.keys status.statuses
    save = []
    Lot.count { status: {$nin: keys} }, (err, count) ->
      done err if err?
      console.log "#{count} lots found"
      stream = Lot.find({ status: {$nin: keys} }).stream()
      stream.on 'data', (lot) ->
        save.push new Promise (resolve) ->
          if lot.status?
            lot.status = status lot.status
            lot.save ->
              count--
              console.log "ETA: #{count} lots"
              resolve()
          else
            count--
            console.log "ETA: #{count} lots"
            resolve()
      stream.on 'end', ->
        Promise.all(save).then done
      stream.on 'error', (err) ->
        done err if err?