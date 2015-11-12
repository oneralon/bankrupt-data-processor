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
    arg = require('optimist').argv.etp
    if arg
      etps = [config.getEtp(arg)]
    else etps = config.etps
    Sync =>
      try
        redis.clear.sync null
        amqp.init.sync null
        for etp in etps
          collector.sync null, etp, null
          exec 'pkill phantomjs'
        log.info "Complete full collecting of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)