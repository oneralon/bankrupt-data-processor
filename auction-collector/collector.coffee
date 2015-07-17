amqp            = require 'amqplib'
Sync            = require 'sync'
request         = require 'request'
config          = require './../config'
log             = require('./../helpers/logger')()
aucUrlQueue     = config.aucUrlQueue
aucHtmlQueue    = config.aucHtmlQueue

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
  Sync =>
    tries = 0
    try
      res = downloadPage.sync @, url
      while res.statusCode isnt 200 and tries < config.getPageTries
        res = downloadPage.sync @, url
        log.info res.statusCode
        tries = tries + 1
      if res.statusCode is 200 then cb null, res.body
      else cb "Error on download #{url}"
    catch e
      log.error e
      cb e

module.exports =
  aucUrlChannel: null
  aucHtmlChannel: null
  connection: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (aucUrlChannel) =>
        aucUrlChannel.prefetch(1)
        aucUrlChannel.assertQueue(aucUrlQueue)
        connection.createChannel().catch(cb).then (aucHtmlChannel) =>
          aucHtmlChannel.assertQueue(aucHtmlQueue)
          cb null,
            aucUrlChannel: aucUrlChannel
            aucHtmlChannel: aucHtmlChannel
            connection: connection

  close: (cb) ->
    @aucUrlChannel.close().catch(cb).then =>
      @aucHtmlChannel.close().catch(cb).then =>
        @connection.close().catch(cb).then =>
          cb()

  start: (number, cb)->
    try
      log.info "Starting auctions HTML collector #{number}"
      interval = setInterval =>
        @aucUrlChannel.assertQueue(aucUrlQueue).then (ok) =>
          if ok.messageCount is 0
            clearInterval interval
            @close(cb)
      , 5000
      Sync =>
        inject @, @init.sync(@)
        @aucUrlChannel.consume aucUrlQueue, (message) =>
          Sync =>
            aucUrl = message.content.toString()
            log.info "Get page #{aucUrl}"
            html = getPage.sync null, aucUrl
            log.info "OK page #{aucUrl}"
            @aucHtmlChannel.sendToQueue aucHtmlQueue, new Buffer(html),
              headers: message.properties.headers
            @aucUrlChannel.ack(message, true)
        , {noAck: false, consumerTag: 'auc-html-collector', exclusive: false}
        log.info 'Consumer of auctions HTML collector started'
    catch e
      log.error e
      cb e