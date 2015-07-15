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

getPage = (url, cb) ->
  opts =
    url: url
    timeout: 120000
  request opts, (err, res, body) =>
    cb err if err?
    cb null, body

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