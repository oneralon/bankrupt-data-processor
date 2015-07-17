amqp            = require 'amqplib'
Sync            = require 'sync'
jsdom           = require 'jsdom'
mongoose        = require 'mongoose'
fs              = require 'fs'
_               = require 'lodash'
config          = require './../config'
log             = require('./../helpers/logger')()
lotHtmlQueue    = config.lotHtmlQueue
jquery          = fs.readFileSync("#{__dirname}/../vendor/jquery.js").toString()

parsers =
  lot_info:      require './../fieldsets/lot_info'
  lot_intervals: require './../fieldsets/lot_intervals'
  lot_documents: require './../fieldsets/lot_documents'

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

dbInsert = (auctions, item, aucUrl, cb) ->
  auctions.findOne {url: aucUrl}, (err, res) =>
    cb err if err?
    auctions.update {url: aucUrl}, {$push: {lots: item}}, (err, res) =>
      cb err if err?
      cb()

module.exports =
  lotHtmlChannel: null
  connection: null
  lots: null
  auctions: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (lotHtmlChannel) =>
        lotHtmlChannel.prefetch(1)
        lotHtmlChannel.assertQueue(lotHtmlQueue)
        mongoose.connection.on 'error', log.error
        mongoose.connect "mongodb://localhost/#{config.tmpDB}"
        lots = mongoose.connection.collection 'lots'
        auctions = mongoose.connection.collection 'auctions'
        cb null,
          lotHtmlChannel: lotHtmlChannel
          connection: connection
          lots: lots
          auctions: auctions

  close: (cb) ->
    @lotHtmlChannel.close().catch(cb).then =>
      @connection.close().catch(cb).then =>
        cb()

  start: (number, cb)->
    try
      log.info "Starting lot HTML parser #{number}"
      interval = setInterval =>
        @lotHtmlChannel.assertQueue(lotHtmlQueue).then (ok) =>
          if ok.messageCount is 0
            clearInterval interval
            @close(cb)
      , 5000
      Sync =>
        inject @, @init.sync(@)
        @lotHtmlChannel.consume lotHtmlQueue, (message) =>
          lotUrl = message.properties.headers.lotUrl
          lotUrl = message.properties.headers.lotUrl
          aucUrl = message.properties.headers.aucUrl
          aucUrl = message.properties.headers.aucUrl
          etpName = message.properties.headers.etpName
          etpUrl  = message.properties.headers.etpUrl
          Sync =>
            html = message.content.toString()
            log.info lotUrl
            window = getWindow.sync null, html
            lot_info = parsers.lot_info.sync null, window.$
            lot_info.url = lotUrl
            lot_info.intervals = parsers.lot_intervals.sync null, window.$
            lot_info.documents = parsers.lot_documents.sync null, window.$, etpUrl
            unless _.isEmpty lot_info.intervals
              now = new Date()
              next_interval_index = 1 + _.findLastIndex lot_info.intervals, (item) ->
                now > item.interval_end_date
              if (now > lot_info.intervals[next_interval_index].interval_start_date)
                current_interval = lot_info.intervals[next_interval_index]
              else
                current_interval = lot_info.intervals[next_interval_index - 1]
            lot_info.current_sum = lot_info.current_sum or current_interval?.interval_price or lot_info.start_price
            lot_info.discount = lot_info.start_price - lot_info.current_sum
            lot_info.discount_percent = lot_info.discount / lot_info.start_price
            dbInsert.sync @, @auctions, lot_info, aucUrl
            log.info "Inserted to DB"
            @lotHtmlChannel.ack(message, true)
        , {noAck: false, consumerTag: 'lot-parser', exclusive: false}
        log.info "Consumer of lot HTML parser #{number} started"
    catch e
      log.error e
      cb e