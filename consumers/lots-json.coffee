cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
mongo      = require '../helpers/mongo'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'LOT JSON CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.lotJsonWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "Lot JSON consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Lot JSON consumer worker exit with code #{code}"
    else log.info "Lot JSON consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "Lot JSON consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.lotsJsonQueue, (message, cb) =>
    if message?
      headers     = message.properties.headers
      etp         = headers.etp
      lot         = JSON.parse message.content.toString()
      Sync =>
        try
          mongo.updateLot.sync null, lot
          cb()
        catch e
          cb e