amqp       = require 'amqplib'
Sync       = require 'sync'
config     = require '../config'
logger     = require '../helpers/logger'

module.exports.consume = (queue, handler) ->
  log = logger "QUEUE #{queue} COMSUMER"
  error = (err) =>
    log.error err
  log.info 'Start comsuming'
  amqp.connect(config.amqpUrl).catch(error).then (connection) =>
    connection.createChannel().catch(error).then (channel) =>
      channel.prefetch(1)
      channel.assertQueue(queue, {durable: true})
      channel.consume queue, (message) =>
        Sync =>
          try
            handler.sync null, message
            channel.ack(message, true)
          catch e
            log.error e
            process.exit 1
      ,
        noAck: false
        consumerTag: 'comsumer'
        exclusive: false

module.exports.publish = (queue, message, headers, cb) ->
  log = logger "QUEUE #{queue} PUBLISH"
  error = (err) =>
    log.error err
    cb err
  log.info 'Publish message'
  message = '' unless message?
  amqp.connect(config.amqpUrl).catch(error).then (connection) =>
    connection.on 'error', (e) -> cb e
    connection.createChannel().catch(error).then (channel) =>
      headers = headers or {}
      headers.persistent = true
      headers.deliveryMode = 2
      channel.publish('', queue, new Buffer(message), headers)
      channel.close().catch(error).then ->
        connection.close().catch(error).then ->
          cb()

module.exports.check = (queue, cb) ->
  log = logger "AMQP"
  error = (err) =>
    log.error err
    cb err
  amqp.connect(config.amqpUrl).catch(error).then (connection) =>
    connection.createChannel().catch(error).then (channel) =>
      if typeof queue is 'String'
        channel.assertQueue(queue).then (ok) =>
          cb null, ok.messageCount isnt 0
      else
        result = []
        channel.assertQueue(config.listsHtmlQueue).then (ok) =>
          result.push ok.messageCount is 0
          channel.assertQueue(config.tradeUrlsQueue).then (ok) =>
            result.push ok.messageCount is 0
            channel.assertQueue(config.tradeHtmlQueue).then (ok) =>
              result.push ok.messageCount is 0
              channel.assertQueue(config.lotsUrlsQueue).then (ok) =>
                result.push ok.messageCount is 0
                channel.assertQueue(config.lotsHtmlQueue).then (ok) =>
                  result.push ok.messageCount is 0
                  setTimeout =>
                    channel.assertQueue(config.listsHtmlQueue).then (ok) =>
                      result.push ok.messageCount is 0
                      channel.assertQueue(config.tradeUrlsQueue).then (ok) =>
                        result.push ok.messageCount is 0
                        channel.assertQueue(config.tradeHtmlQueue).then (ok) =>
                          result.push ok.messageCount is 0
                          channel.assertQueue(config.lotsUrlsQueue).then (ok) =>
                            result.push ok.messageCount is 0
                            channel.assertQueue(config.lotsHtmlQueue).then (ok) =>
                              result.push ok.messageCount is 0
                              log.info "AMQP check #{result.indexOf(false) isnt -1}"
                              channel.close().catch(error).then =>
                                connection.close().catch(error).then =>
                                  cb null, result.indexOf(false) isnt -1
                  , 1000


module.exports.init = (cb) ->
  log = logger "AMQP"
  log.info 'Init queues'
  error = (err) =>
    log.error err
    cb err
  amqp.connect(config.amqpUrl).catch(error).then (connection) ->
    connection.createChannel().catch(error).then (channel) ->
      channel.assertQueue(config.listsHtmlQueue, {durable: true, noAck: false}).then ->
        channel.assertQueue(config.tradeUrlsQueue, {durable: true, noAck: false}).then ->
          channel.assertQueue(config.tradeHtmlQueue, {durable: true, noAck: false}).then ->
            channel.assertQueue(config.lotsUrlsQueue, {durable: true, noAck: false}).then ->
              channel.assertQueue(config.lotsHtmlQueue, {durable: true, noAck: false}).then ->
                channel.close().catch(error).then () ->
                  connection.close().catch(error).then () ->
                  cb()