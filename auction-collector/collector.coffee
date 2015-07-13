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

getPage = (url, cb) ->
  opts =
    url: url
    timeout: config.timeout
  request opts, (err, res, body) =>
    cb err if err?
    cb null, body

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
    log.info "Starting auctions HTML collector #{number}"
    Sync =>
      inject @, @init.sync(@)
      @aucUrlChannel.consume aucUrlQueue, (message) =>
        Sync =>
          aucUrl = message.content.toString()
          log.info "Get page #{aucUrl}"
          html = getPage.sync null, aucUrl
          log.info "OK page #{aucUrl}"
          @aucHtmlChannel.sendToQueue aucHtmlQueue, new Buffer(html), {headers: {url: aucUrl}}
          @aucUrlChannel.ack(message, true)
      , {noAck: false, consumerTag: 'auc-html-collector', exclusive: false}
      log.info 'Consumer of auctions HTML collector started'