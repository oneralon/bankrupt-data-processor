redis     = require 'redis'
logger    = require '../helpers/logger'
log       = logger  'REDIS'
config    = require '../config'

module.exports.check = (url, cb) =>
  client = redis.createClient()
  client.on 'error', (err) ->
    log.error err
    cb err
  client.get url, (err, reply) =>
    cb err if err?
    if reply is null or new Date() - new Date(reply) > 300000
      client.set url, (new Date()).toString()
      log.info "Redis check #{url} true"
      cb null, true
    else
      log.info "Redis check #{url} false"
      cb null, false

module.exports.clear = (cb) ->
  client = redis.createClient()
  client.on 'error', (err) ->
    log.error err
    cb err
  client.flushall (err) =>
    log.info 'Clear redis DB'
    cb err if err?
    cb()