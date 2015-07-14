cluster   = require 'cluster'
parser    = require './parser'
config    = require './../config'
log       = require('./../helpers/logger')()

if cluster.isMaster
  i = 0
  while i < config.listHtmlWorkers
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "List HTML parser worker exit with signal #{signal}"
    else log.info "List HTML parser worker exit with signal #{signal}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  parser.start cluster.worker.process.pid, (err) ->
    if err?
      log.error err
      process.exit 1
    else process.exit 0