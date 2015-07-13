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

dbInsert = (collection, item, cb) ->
  collection.insert item, (err, res) ->
    cb err if err?
    cb null, res

module.exports =
  lotHtmlChannel: null
  connection: null
  collection: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (lotHtmlChannel) =>
        lotHtmlChannel.prefetch(1)
        lotHtmlChannel.assertQueue(lotHtmlQueue)
        mongoose.connection.on 'error', log.error
        mongoose.connect "mongodb://localhost/#{config.tmpDB}"
        collection = mongoose.connection.collection 'lots'
        cb null,
          lotHtmlChannel: lotHtmlChannel
          connection: connection
          collection: collection

  close: (cb) ->
    @lotHtmlChannel.close().catch(cb).then =>
      @connection.close().catch(cb).then =>
        cb()

  start: (number, cb)->
    log.info "Starting lot HTML parser #{number}"
    Sync =>
      inject @, @init.sync(@)
      @lotHtmlChannel.consume lotHtmlQueue, (message) =>
        Sync =>
          html = message.content.toString()
          lotUrl = message.properties.headers.url
          log.info lotUrl
          window = getWindow.sync null, html
          lot_info = parsers.lot_info.sync null, window.$
          lot_info.url = lotUrl
          lot_info.intervals = parsers.lot_intervals.sync null, window.$
          lot_info.documents = parsers.lot_documents.sync null, window.$
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
          dbInsert.sync null, @collection, lot_info
          log.info "Inserted to DB"
          @lotHtmlChannel.ack(message, true)
      , {noAck: false, consumerTag: 'lot-parser', exclusive: false}
      log.info "Consumer of lot HTML parser #{number} started"