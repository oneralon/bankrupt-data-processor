amqp            = require 'amqplib'
Sync            = require 'sync'
jsdom           = require 'jsdom'
fs              = require 'fs'
redis           = require 'redis'
config          = require './../config'
log             = require('./../helpers/logger')()
listsQueue      = config.listsQueue
auctionsQueue   = config.auctionsQueue
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
  auctionsChannel: null
  redis: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (listsChannel) =>
        listsChannel.prefetch(1)
        listsChannel.assertQueue(listsQueue)
        connection.createChannel().catch(cb).then (auctionsChannel) =>
          auctionsChannel.assertQueue(auctionsQueue)
          redis = redis.createClient()
          redis.on 'error', (err) ->
            throw new err
          cb null,
            listsChannel: listsChannel
            auctionsChannel: auctionsChannel
            connection: connection
            redis: redis

  close: (cb) ->
    @listsChannel.close().catch(cb).then =>
      @auctionsChannel.close().catch(cb).then =>
        @connection.close().catch(cb).then =>
          cb()

  start: (cb)->
    Sync =>
      inject @, @init.sync(@)
      @listsChannel.consume listsQueue, (message) =>
        if message isnt null
          html = message.content.toString()
          jsdom.env html, src: [jquery], (err, window) =>
            auctions = window.$('tr.gridRow td a.purchase-type-auction-open')
            uniqAucs = []
            for auction in auctions
              url = message.properties.headers.url + window.$(auction).attr('href')
              if window.$.inArray(url, uniqAucs) is -1
                uniqAucs.push url
            Sync =>
              for url in uniqAucs
                reply = redisGet.sync null, @redis, url
                if reply is null
                  @auctionsChannel.sendToQueue auctionsQueue, new Buffer(url), {}
                  @redis.set url, new Date()
                else
                  if (new Date()) - (new Date(reply)) > 3600000 # 1 hour
                    @redis.set url, new Date()
            @listsChannel.ack(message, true)
      , {noAck: false, consumerTag: 'parser', exclusive: true}
      log.info 'Consumer started'