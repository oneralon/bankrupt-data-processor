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
    done = @async()
    argv = require('optimist').argv
    etps = config.etps
    if argv.etp?
      etps = etps.filter (i) -> new RegExp(argv.etp.replace('.', '\.').replace('-', '\-')).test i.href
    if argv.platform?
      etps = etps.filter (i) -> new RegExp(argv.platform.replace('.', '\.').replace('-', '\-')).test i.platform
    log.info "Start full collecting of #{etps.length} sources"
    Sync =>
      try
        redis.clear.sync null
        amqp.init.sync null
        for etp in etps
          collector.sync null, etp, null, false
          exec 'pkill phantomjs'
        log.info "Complete full collecting of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)