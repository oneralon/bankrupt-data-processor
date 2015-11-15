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
    if message? and message.content.toString().length > 5
      headers     = message.properties.headers
      #parser      = require "../parsers/#{headers.parser}"
      etp         = headers.etp
      html        = message.content.toString()
      Sync =>
        try
          if /undefined/i.test headers.url then cb()
          queue = config.lotsJsonQueue
          if headers.etp.platform is 'sberbank-ast' 
            parser      = require "../parsers/#{headers.parser}"
            lot = parser.sync null, html, null, etp
          else
            if /fabrikant/i.test headers.etp.href
              parser = require "../parsers/fabrikant/trade"
              lot = parser.sync null, html, etp, headers.url, null
              queue = config.tradesJsonQueue
            else
              parser      = require "../parsers/#{headers.parser}"
              lot = parser html, etp
          unless lot?
            console.log headers.url
            return cb()
          lot.url = headers.url
          lot.tradeUrl = headers.tradeUrl
          amqp.publish.sync null, queue, JSON.stringify(lot), headers: headers
          cb()
        catch e
          log.error e
          cb e
    else cb()
