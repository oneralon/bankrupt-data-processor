cluster   = require 'cluster'
collector = require './collector'
config    = require './../config'
log       = require('./../helpers/logger')()

if cluster.isMaster
  i = 0
  while i < config.lotUrlWorkers
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Lots HTML collector worker exit with signal #{signal}"
    else log.info "Lots HTML collector worker exit with signal #{signal}"
else
  collector.start cluster.worker.process.pid, (err) ->
    if err?
      log.error err
      process.exit(1)
    else process.exit(0)