config     = require './../config'
collector  = require './collector'
log        = require('./../helpers/logger')()

collector.collect config.urls, (err) ->
  if err?
    log.error err
    process.exit(1)
  else process.exit(0)