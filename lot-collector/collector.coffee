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
    timeout: config.timeout
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
    log.info "Starting auctions HTML collector #{number}"
    Sync =>
      inject @, @init.sync(@)
      @lotUrlChannel.consume lotUrlQueue, (message) =>
        Sync =>
          lotUrl = message.content.toString()
          log.info "Get page #{lotUrl}"
          html = getPage.sync null, lotUrl
          log.info "OK page #{lotUrl}"
          @lotHtmlChannel.sendToQueue lotHtmlQueue, new Buffer(html), {headers: {url: lotUrl}}
          @lotUrlChannel.ack(message, true)
      , {noAck: false, consumerTag: 'auc-html-collector', exclusive: false}
      log.info 'Consumer of auctions HTML collector started'