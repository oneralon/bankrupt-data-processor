cluster   = require 'cluster'
collector = require './collector'
config    = require './../config'
log       = require('./../helpers/logger')()

if cluster.isMaster
  i = 0
  while i < config.aucUrlWorkers
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Auctions HTML collector worker exit with signal #{signal}"
    else log.info "Auctions HTML collector worker exit with signal #{signal}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  collector.start cluster.worker.process.pid, (err) ->
    if err?
      log.error err
      process.exit 1
    else process.exit 0