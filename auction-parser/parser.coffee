amqp            = require 'amqplib'
Sync            = require 'sync'
jsdom           = require 'jsdom'
mongoose        = require 'mongoose'
fs              = require 'fs'
config          = require './../config'
log             = require('./../helpers/logger')()
aucHtmlQueue    = config.aucHtmlQueue
jquery          = fs.readFileSync("#{__dirname}/../vendor/jquery.js").toString()

parsers =
  trade_owner:          require './../fieldsets/trade_owner'
  trade_owner_contact:  require './../fieldsets/trade_owner_contact'
  auction_info:         require './../fieldsets/auction_info'
  debtor_info:          require './../fieldsets/debtor_info'
  auction_documents:    require './../fieldsets/auction_documents'

inject    = (to, from)->
  for key, val of from
    to[key] = val

getWindow = (html, cb) ->
  jsdom.env
    html: html
    src: [jquery]
    done: (err, window) =>
      cb err if err?
      cb null, window

dbInsert = (collection, item, cb) ->
  collection.insert item, (err, res) ->
    cb err if err?
    cb null, res

module.exports =
  aucHtmlChannel: null
  connection: null
  collection: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (aucHtmlChannel) =>
        aucHtmlChannel.prefetch(1)
        aucHtmlChannel.assertQueue(aucHtmlQueue)
        mongoose.connection.on 'error', log.error
        mongoose.connect "mongodb://localhost/#{config.tmpDB}"
        collection = mongoose.connection.collection 'auctions'
        cb null,
          aucHtmlChannel: aucHtmlChannel
          connection: connection
          collection: collection

  close: (cb) ->
    @aucHtmlChannel.close().catch(cb).then =>
      @connection.close().catch(cb).then =>
        cb()

  start: (number, cb)->
    try
      log.info "Starting auction HTML parser #{number}"
      interval = setInterval =>
        @aucHtmlChannel.assertQueue(aucHtmlQueue).then (ok) =>
          if ok.messageCount is 0
            clearInterval interval
            @close(cb)
      , 60000
      Sync =>
        inject @, @init.sync(@)
        @aucHtmlChannel.consume aucHtmlQueue, (message) =>
          etpUrl = message.properties.headers.etpUrl
          aucUrl = message.properties.headers.aucUrl
          aucNum = message.properties.headers.aucNum
          Sync =>
            html = message.content.toString()
            log.info aucUrl
            window = getWindow.sync null, html
            info = parsers.auction_info.sync null, window.$
            info.url = aucUrl
            info.number = aucNum
            info.lots = []
            info.owner = parsers.trade_owner.sync null, window.$
            info.owner.contact = parsers.trade_owner_contact.sync null, window.$
            info.debtor = parsers.debtor_info.sync null, window.$
            info.region = info.debtor.region
            info.documents = parsers.auction_documents.sync null, window.$, etpUrl
            dbInsert.sync null, @collection, info
            log.info "Inserted to DB"
            @aucHtmlChannel.ack(message, true)
        , {noAck: false, consumerTag: 'auc-parser', exclusive: false}
        log.info "Consumer of auction HTML parser #{number} started"
    catch e
      log.error e
      cb e