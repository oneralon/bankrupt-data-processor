cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'TRADE URL CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.tradeUrlWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "Trade URL consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
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
          if headers.etp.platform is 'lot-online'
            result = ['', {}]
          else
            result = downloader.sync null, headers.url
          for k, v of result[1]
            headers[k] = v
          amqp.publish.sync null, headers.queue, result[0], headers: headers
          cb()
        catch e
          cb e