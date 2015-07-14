amqp            = require 'amqplib'
Sync            = require 'sync'
jsdom           = require 'jsdom'
fs              = require 'fs'
redis           = require 'redis'
config          = require './../config'
log             = require('./../helpers/logger')()
listsQueue      = config.listsQueue
aucUrlQueue     = config.aucUrlQueue
lotUrlQueue     = config.lotUrlQueue
jquery          = fs.readFileSync("#{__dirname}/../vendor/jquery.js").toString()

inject    = (to, from)->
  for key, val of from
    to[key] = val

redisGet = (redis, url, cb) ->
  redis.get url, (err, reply) ->
    if err? then cb err
    else cb null, reply

module.exports =
  connection: null
  listsChannel: null
  aucUrlChannel: null
  lotUrlChannel: null
  redis: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (listsChannel) =>
        listsChannel.prefetch(1)
        listsChannel.assertQueue(listsQueue)
        connection.createChannel().catch(cb).then (aucUrlChannel) =>
          aucUrlChannel.assertQueue(aucUrlQueue)
          connection.createChannel().catch(cb).then (lotUrlChannel) =>
            lotUrlChannel.assertQueue(lotUrlQueue)
            redis = redis.createClient()
            redis.on 'error', (err) ->
              throw new err
            redis.flushall (err) =>
              if err? then cb err
              cb null,
                listsChannel: listsChannel
                aucUrlChannel: aucUrlChannel
                lotUrlChannel: lotUrlChannel
                connection: connection
                redis: redis

  close: (cb) ->
    @listsChannel.close().catch(cb).then =>
      @aucUrlChannel.close().catch(cb).then =>
        @connection.close().catch(cb).then =>
          cb()

  start: (number, cb)->
    log.info "Starting list HTML parser #{number}"
    interval = setInterval =>
      @listsChannel.assertQueue(listsQueue).then (ok) =>
        if ok.messageCount is 0
          clearInterval interval
          @close(cb)
    , 5000
    Sync =>
      inject @, @init.sync(@)
      @listsChannel.consume listsQueue, (message) =>
        etpUrl = message.properties.headers.url
        if message isnt null
          html = message.content.toString()
          jsdom.env html, src: [jquery], (err, window) =>
            rows = window.$("[id*='ctl00_ctl00_MainContent'] > tbody > tr.gridRow")
            log.info "Rows #{rows.length}"
            for row in rows
              Sync =>
                lotUrl = etpUrl + window.$(row).find("td > a.tip-lot").attr('href')
                @lotUrlChannel.sendToQueue lotUrlQueue, new Buffer(lotUrl), {auction: etpUrl}
                aucUrl = etpUrl + window.$(row).find("td > a.purchase-type-auction-open, td > a.tip-purchase").attr('href')
                if typeof window.$(row).find("td > a.purchase-type-auction-open, td > a.tip-purchase").attr('href') is 'undefined'
                  cb "Undefined url #{etpUrl}"
                reply = redisGet.sync null, @redis, aucUrl
                if reply is null
                  @aucUrlChannel.sendToQueue aucUrlQueue, new Buffer(aucUrl), {}
                  @redis.set aucUrl, new Date()
                else
                  if (new Date()) - (new Date(reply)) > 600000 # 10 minute
                    @aucUrlChannel.sendToQueue aucUrlQueue, new Buffer(aucUrl), {}
                    @redis.set aucUrl, new Date()
            @listsChannel.ack(message, true)
      , {noAck: false, consumerTag: 'parser', exclusive: false}
      log.info "Consumer of list HTML parser (#{number}) started"