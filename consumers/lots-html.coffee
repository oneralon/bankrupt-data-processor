cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
mongo      = require '../helpers/mongo'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'LOT HTML CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.lotHtmlWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "Lot HTML consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Lot HTML consumer worker exit with code #{code}"
    else log.info "Lot HTML consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "Lot HTML consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.lotsHtmlQueue, (message, cb) =>
    if message?
      headers     = message.properties.headers
      parser      = require "../parsers/#{headers.parser}"
      etp         = headers.etp
      html        = message.content.toString()
      Sync =>
        try
          lot = parser html, etp
          lot.url = headers.url
          lot.tradeUrl = headers.tradeUrl
          amqp.publish.sync null, config.lotsJsonQueue, JSON.stringify(lot), headers: headers
          cb()
        catch e
          log.error e
          cb e