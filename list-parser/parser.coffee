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
host            = /^https?\:\/\/[A-Za-z0-9\.\-]+/

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
    try
      log.info "Starting list HTML parser #{number}"
      interval = setInterval =>
        @listsChannel.assertQueue(listsQueue).then (ok) =>
          if ok.messageCount is 0
            clearInterval interval
            @close(cb)
      , 60000
      Sync =>
        inject @, @init.sync(@)
        @listsChannel.consume listsQueue, (message) =>
          etpUrl = message.properties.headers.url
          if message isnt null
            html = message.content.toString()
            jsdom.env html, src: [jquery], (err, window) =>
              rows = window.$("[id*='ctl00_ctl00_MainContent'] > tbody > tr.gridRow")
              log.info "Rows #{rows.length}"
              Sync =>
                for row in rows
                  lot = window.$(row).find("td.gridColumn a.tip-lot")
                  lotUrl = etpUrl.match(host)[0] + lot.attr('href')
                  lotName = lot.html()
                  if typeof lotUrl is 'undefined'
                    log.error "LOT: #{lotUrl}"
                    cb "Undefined url #{etpUrl}"
                  auc = window.$(row).find("td.gridAltColumn a[class*='purchase-type-']")
                  aucUrl = etpUrl.match(host)[0] + auc.attr('href')
                  aucNum = auc.html()
                  @lotUrlChannel.sendToQueue lotUrlQueue, new Buffer(lotUrl),
                    headers:
                      lotName: lotName
                      lotUrl: lotUrl
                      aucNum: aucNum
                      aucUrl: aucUrl
                      etpUrl: etpUrl
                      etpName: config.urls[etpUrl]
                  if typeof aucNum is 'undefined'
                    log.error "AUC: #{aucUrl}"
                    cb "Undefined url #{etpUrl}"
                  reply = redisGet.sync null, @redis, aucUrl
                  if reply is null
                    @aucUrlChannel.sendToQueue aucUrlQueue, new Buffer(aucUrl),
                      headers:
                        aucNum: aucNum
                        aucUrl: aucUrl
                        etpUrl: etpUrl
                        etpName: config.urls[etpUrl]
                    @redis.set aucUrl, true
                @listsChannel.ack(message, true)
        , {noAck: false, consumerTag: 'parser', exclusive: false}
        log.info "Consumer of list HTML parser (#{number}) started"
    catch e
      log.error e
      cb e