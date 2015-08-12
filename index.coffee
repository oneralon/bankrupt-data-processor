Sync      = require 'sync'
redis     = require './helpers/redis'
amqp      = require './helpers/amqp'
consumers = require './helpers/consumers'
mongo     = require './helpers/mongo'
collector = require './helpers/collector'
logger    = require './helpers/logger'
log       = logger  'MAIN'

config    = require './config'

proceed = (etp, cb) ->
  Sync =>
    try
      redis.clear.sync null
      amqp.init.sync null
      collector.collect.sync null, etp
      consumers.start()
      watchdog = setInterval =>
        Sync =>
          try
            working = amqp.check.sync null, null
            if not working
              clearInterval watchdog
              consumers.stop()
              mongo.build.sync null, etp
              mongo.convert.sync null, etp
              cb()
          catch e then cb e
      , 10000
    catch e then cb e

Sync =>
  try
    for etp in config.etps
      proceed.sync null, etp
    log.info 'All etps completed'
    process.exit 0
  catch e
    log.error err
    process.exit 1