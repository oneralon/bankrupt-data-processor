cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
mongo      = require '../helpers/mongo'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE HTML CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.tradeHtmlWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "Trade HTML consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Trade HTML consumer worker exit with code #{code}"
    else log.info "Trade HTML consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "Trade HTML consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.tradeHtmlQueue, (message, cb) =>
    if message?
      headers     = message.properties.headers
      parser      = require "../parsers/#{headers.parser}"
      etp         = headers.etp
      html        = message.content.toString()
      Sync =>
        try
          trade = parser.sync null, html, etp, headers.url
          trade.url = headers.url
          trade.etp = etp
          amqp.publish.sync null, config.tradeJsonQueue, JSON.stringify(trade), headers: headers
          cb()
        catch e
          log.error e
          cb e