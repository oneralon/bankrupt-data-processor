Forever    = require 'forever-monitor'
Sync       = require 'sync'

logger     = require '../helpers/logger'
log        = logger  'COLLECTOR FOREVER'

collector  = require '../helpers/collector'
redis      = require '../helpers/redis'
amqp       = require '../helpers/amqp'
config     = require '../config'

module.exports = (grunt) ->
  grunt.registerTask 'collect:full', ->
    log.info "Start full collecting of #{config.etps.length} sources"
    done = @async()
    Sync =>
      try
        for etp in config.etps
          redis.clear.sync null
          amqp.init.sync null
          collector.sync null, etp, null
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
        log.info "Complete updating of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)