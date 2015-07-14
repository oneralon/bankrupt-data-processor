cluster   = require 'cluster'
parser    = require './parser'
config    = require './../config'
log        = require('./../helpers/logger')()

if cluster.isMaster
  i = 0
  while i < config.lotHtmlWorkers
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Lots HTML parser worker exit with code #{code}"
    else log.info "Lots HTML parser worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  parser.start cluster.worker.process.pid, (err) ->
    if err?
      log.error err
      process.exit 1
    else process.exit 0