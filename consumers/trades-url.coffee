cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE URL CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.lotUrlWorkers
    cluster.fork()
    i++
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "Trade URL consumer worker exit with code #{code}"
    else log.info "Trade URL consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "Trade URL consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.tradeUrlsQueue, (message, cb) =>
    if message?
      headers     = message.properties.headers
      downloader  = require "../downloaders/#{headers.downloader}"
      etp         = headers.etp
      Sync =>
        try
          html = downloader.sync null, headers.url
          amqp.publish.sync null, headers.queue, html, headers: headers
          cb()
        catch e
          cb e    