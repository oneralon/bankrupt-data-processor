amqp            = require 'amqplib'
Sync            = require 'sync'
request         = require 'request'
config          = require './../config'
log             = require('./../helpers/logger')()
lotUrlQueue     = config.lotUrlQueue
lotHtmlQueue    = config.lotHtmlQueue

inject    = (to, from)->
  for key, val of from
    to[key] = val

downloadPage = (url, cb) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  request.get(url,{
    options:
      headers:
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
        'Accept-Language': 'en-US,en;q=0.8'
        'Cache-Control': 'max-age=0'
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  }).on 'error', (err) -> cb err
  .on 'response', (response) -> cb null, response
  .on 'timeout', -> cb "Reset by timeout #{url}"

getPage = (url, cb) ->
  try
    Sync =>
      tries = 0
      res = downloadPage.sync @, url
      while res.statusCode isnt 200 and tries < config.getPageTries
        tries = tries + 1
        res = downloadPage.sync @, url
        if res.statusCode is 200 then cb null, res.body
        else cb "Error on download #{url}"
  catch e
    log.error e
    cb e

module.exports =
  lotUrlChannel: null
  lotHtmlChannel: null
  connection: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (lotUrlChannel) =>
        lotUrlChannel.prefetch(1)
        lotUrlChannel.assertQueue(lotUrlQueue)
        connection.createChannel().catch(cb).then (lotHtmlChannel) =>
          lotHtmlChannel.assertQueue(lotHtmlQueue)
          cb null,
            lotUrlChannel: lotUrlChannel
            lotHtmlChannel: lotHtmlChannel
            connection: connection

  close: (cb) ->
    @lotUrlChannel.close().catch(cb).then =>
      @lotHtmlChannel.close().catch(cb).then =>
        @connection.close().catch(cb).then =>
          cb()

  start: (number, cb)->
    log.info "Starting lots HTML collector #{number}"
    interval = setInterval =>
      @lotUrlChannel.assertQueue(lotUrlQueue).then (ok) =>
        if ok.messageCount is 0
          clearInterval interval
          @close(cb)
    , 5000
    try
      Sync =>
        inject @, @init.sync(@)
        @lotUrlChannel.consume lotUrlQueue, (message) =>
          Sync =>
            lotUrl = message.content.toString()
            log.info "Get page #{lotUrl}"
            html = getPage.sync null, lotUrl
            log.info "OK page #{lotUrl}"
            @lotHtmlChannel.sendToQueue lotHtmlQueue, new Buffer(html),
              headers: message.properties.headers
            @lotUrlChannel.ack(message, true)
        , {noAck: false, consumerTag: 'auc-html-collector', exclusive: false}
        log.info 'Consumer of lots HTML collector started'
    catch e
      log.error e
      cb e