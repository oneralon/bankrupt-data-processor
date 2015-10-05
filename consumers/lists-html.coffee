cluster    = require 'cluster'
Sync       = require 'sync'
amqp       = require '../helpers/amqp'
config     = require '../config'
logger     = require '../helpers/logger'
log        = logger  'LIST HTML CONSUMER'

if cluster.isMaster
  i = 0
  while i < config.listWorkers
    cluster.fork()
    i++
  cluster.on 'disconnect', (worker) ->
    log.error "List HTML consumer worker #{worker.process.pid} disconnected"
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    unless code is 0
      log.error "List HTML consumer worker exit with code #{code}"
    else log.info "List HTML consumer worker exit with code #{code}"
    if Object.keys(cluster.workers).length is 0 then process.exit 0
else
  log.info "List HTML consumer worker #{cluster.worker.process.pid}"
  amqp.consume config.listsHtmlQueue, (message, cb) =>
    if message?
      headers = message.properties.headers
      parser  = require "../parsers/#{headers.parser}"
      etp     = headers.etp
      html    = message.content.toString('utf8')
      parser html, etp, (err, result) =>
        cb err if err?
        Sync =>
          try
            for trade in result
              amqp.publish.sync null, config.tradeUrlsQueue, null, headers: trade
            cb()
          catch e
            cb e