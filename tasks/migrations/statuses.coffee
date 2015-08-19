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
    Lot.find { status: {$nin: keys} }, (err, lots) ->
      console.log "#{lots.length} lots found"
      done err if err?
      save = []
      for lot in lots
        save.push new Promise (resolve) ->
          lot.status = status lot.status
          lot.save resolve
      Promise.all(save).then done