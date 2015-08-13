cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE JSON CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.tradeUrlWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "Trade JSON consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Trade JSON consumer worker exit with code #{code}"
    else log.info "Trade JSON consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "Trade JSON consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.tradeJsonQueue, (message, cb) =>
    if message?
      headers     = message.properties.headers
      etp         = headers.etp
      auction     = JSON.parse message.content.toString()
      Sync =>
        try
          mongo.insert.sync null, 'trades', auction
          cb()
        catch e
          cb e