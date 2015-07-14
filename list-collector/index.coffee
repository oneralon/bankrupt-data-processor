cluster   = require 'cluster'
collector = require './collector'
config    = require './../config'
log       = require('./../helpers/logger')()

if cluster.isMaster
  i = 0
  while i < 1
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "List HTML collector worker exit with signal #{signal}"
    else log.info "List HTML collector worker exit with signal #{signal}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  collector.collect config.urls, (err) ->
    if err?
      log.error err
      process.exit 1
    else process.exit 0