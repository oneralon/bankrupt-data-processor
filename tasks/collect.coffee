Forever    = require 'forever-monitor'
Sync       = require 'sync'
exec       = require('child_process').exec

logger     = require '../helpers/logger'
log        = logger  'COLLECTOR FOREVER'

collector  = require '../helpers/collector'
redis      = require '../helpers/redis'
amqp       = require '../helpers/amqp'
config     = require '../config'

module.exports = (grunt) ->
  grunt.registerTask 'collect:init', ->
    done = @async()
    amqp.init(done)

  grunt.registerTask 'collect:full', ->
    log.info "Start full collecting of #{config.etps.length} sources"
    done = @async()
    Sync =>
      try
        redis.clear.sync null
        amqp.init.sync null
        for etp in config.etps
          collector.sync null, etp, null
          exec 'pkill phantomjs'
        log.info "Complete full collecting of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)

  grunt.registerTask 'collect:update', ->
    log.info "Start updating of #{config.etps.length} sources"
    done = @async()
    Sync =>
      try
        for etp in config.etps
          redis.clear.sync null
          amqp.init.sync null
          collector.sync null, etp, config.incUpdTime
        exec 'pkill phantomjs'
        log.info "Complete updating of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)