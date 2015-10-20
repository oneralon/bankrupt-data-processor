mongoose   = require 'mongoose'
Sync       = require 'sync'
exec       = require('child_process').exec
collector  = require '../helpers/collector'
redis      = require '../helpers/redis'
amqp       = require '../helpers/amqp'
config     = require '../config'
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/lot'
Lot       = сonnection.model 'Lot'

module.exports = (grunt) ->
  grunt.registerTask 'cron:present', ->
    console.log 'Update present field' 
    done = @async()
    Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, (err, result) ->
      done(err) if err?
      console.log 'Updated: ' + result.nModified
      done()

  grunt.registerTask 'cron:recollect', ->
    console.log "Start updating of #{config.etps.length} sources" 
    done = @async()
    Sync =>
      try
        for etp in config.etps
          redis.clear.sync null
          amqp.init.sync null
          collector.sync null, etp, config.incUpdTime
        log.info "Complete updating of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)