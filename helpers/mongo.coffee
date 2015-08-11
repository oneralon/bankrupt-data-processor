mongoose   = require 'mongoose'
Sync       = require 'sync'
Promise    = require 'promise'
moment     = require 'moment'
_          = require 'lodash'
config     = require '../config'
regionize  = require './regionize'
logger     = require '../helpers/logger'
log        = logger  'MONGODB'

tempConnection  = mongoose.createConnection "mongodb://localhost/#{config.tmpDB}"
prodConnection  = mongoose.createConnection "mongodb://localhost/#{config.prodDB}"

require '../models/trade'
require '../models/lot'
require '../models/tag'

Trade     = prodConnection.model 'Trade'
Lot       = prodConnection.model 'Lot'

module.exports.insert = (table, item, cb) ->
  mongoose.connect "mongodb://localhost/#{config.tmpDB}"
  collection = mongoose.connection.collection table
  collection.insert item, (err, res) ->
    cb err if err?
    log.info "Inserted to DB: #{table}"
    mongoose.connection.close()
    cb null, res

module.exports.build = (etp, cb) ->
  etpExp = new RegExp(etp.url.match(/^https?\:\/\/[A-Za-z0-9\.\-]+/i)[0], 'i')
  connection = mongoose.createConnection "mongodb://localhost/#{config.tmpDB}"
  Lots = connection.collection 'lots'
  Trades = connection.collection 'trades'
  promises = []
  Trades.find {}, (err, tradesCursor) ->
    tradesStream = tradesCursor.stream()
    tradesStream.on 'data', (trade) ->
      promises.push new Promise (resolve) ->
        Lots.find {tradeUrl: trade.url}, (err, lotsCursor) ->
          lotsStream = lotsCursor.stream()
          lots = []
          lotsStream.on 'data', (lot) ->
            lots.push lot
          lotsStream.on 'end', ->
            log.info "Trade #{trade.url} has #{lots.length} lots"
            Trades.update {url: trade.url}, {$set: {lots:lots}}, ->
              resolve()
    tradesStream.on 'end', =>
      Promise.all(promises).then () ->
        log.info "Build complete"
        mongoose.connection.close()
        cb()

update_etps = (cb) ->
  Trade.distinct 'etp.name', (err, result) ->
    prodConnection.collection('etps').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, etps) ->
      unless _.isEqual(result.sort(), etps?.list?.sort())
        prodConnection.collection('etps').insert
          list: result
          _v: etps?._v+1 or 0
        , cb
      else cb()

update_statuses = (cb) ->
  Lot.distinct 'status', (err, result) ->
    prodConnection.collection('statuses').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, statuses) ->
      unless _.isEqual(result.sort(), statuses?.list?.sort())
        prodConnection.collection('statuses').insert
          list: result
          _v: statuses?._v+1 or 0
        , cb
      else cb()

update_regions = (cb) ->
  Lot.distinct 'region', (err, result) ->
    prodConnection.collection('regions').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, regions) ->
      unless _.isEqual(result.sort(), regions?.list?.sort())
        prodConnection.collection('regions').insert
          list: result
          _v: regions?._v+1 or 0
        , cb
      else cb()

set_region = (lot) ->
  if not lot.region? or lot.region is 'null'
    lot.region = 'Не определен'

diffpatch =
  diff: (left, right, model) ->
    result = {}
    for k, v of right
      unless v instanceof Object
        switch model.schema.tree[k]
          when String
            equal = String(left[k]) is String(v)
          when Date
            equal = moment(left[k]).format() is moment(v).format()
          when Number
            equal = Number(left[k]) is Number(v)
        unless equal
          if model.schema.tree[k]?
            result[k] = switch model.schema.tree[k]
              when String
                String(v)
              when Date
                moment(v).format()
              when Number
                Number(v)
    result
  patch: (obj, diff) ->
    for k, v of diff
      obj[k] = v

module.exports.convert = (etp, cb) ->
  log = logger  'MONGODB CONVERTER'
  etpExp = new RegExp(etp.url.match(/^https?\:\/\/[A-Za-z0-9\.\-]+/i)[0], 'i')
  log.info 'Start converting temp DB to production DB'
  tempConnection.collection('trades').find {}, (err, cursor) ->
    auc_promises = []
    stream = cursor.stream()
    stream.on 'data', (auc) ->
      log.info "Trade #{auc.url}"
      auc_promises.push new Promise (resolve) ->
        Trade.findOne({url: auc.url}).populate('lots').exec (err, trade) ->
          save_promises = []
          unless trade?
            trade = new Trade()
            if not auc.region or auc.region is 'Не определен'
              trade.region = regionize(auc)
            for k, v of auc
              unless v instanceof Object
                trade[k] = v or undefined
            for auc_lot in auc.lots
              auc_lot.region = auc.region
              lot = new Lot()
              for k, v of auc_lot
                if v?
                  lot[k] = v
                else
                  lot[k] = undefined
              lot.region = trade.region
              lot.trade = trade._id
              save_promises.push new Promise (resolve) ->
                lot.save resolve
              trade.lots.push lot
            trade.owner = auc.owner
            trade.debtor = auc.debtor
            trade.etp = auc.etp
            trade.documents = auc.documents
            save_promises.push new Promise (resolve) ->
              log.info "NEW Trade #{trade.url} region #{trade.region}"
              trade.save -> resolve()
          else
            diff = diffpatch.diff trade, auc, Trade
            diffpatch.patch trade, diff
            trade.owner = auc.owner
            trade.debtor = auc.debtor
            trade.etp = auc.etp
            trade.documents = auc.documents
            save_promises.push new Promise (resolve) ->
              log.info "Trade #{trade.url} region #{trade.region}"
              trade.save -> resolve()
            auc.lots = auc.lots or []
            for auc_lot in auc.lots
              auc_lot.region = auc.region if not auc_lot.region? or auc_lot.region is 'Не определен'
              lot = _.where(trade.lots, {number: Number auc_lot.number})[0]
              if lot?
                diff = diffpatch.diff lot, auc_lot, Lot
                diffpatch.patch lot, diff
                lot.intervals = auc_lot.intervals
                lot.documents = auc_lot.documents
                lot.tagInputs = auc_lot.tagInputs
                lot.tags      = auc_lot.tags
                lot.region    = trade.region
                save_promises.push new Promise (resolve) ->
                  lot.save resolve
              else
                lot = new Lot()
                for k, v of auc_lot
                  if v?
                    lot[k] = v
                  else
                    lot[k] = undefined
                lot.region = trade.region
                lot.trade = trade._id
                save_promises.push new Promise (resolve) ->
                  lot.save resolve
                trade.lots.push lot
          Promise.all(save_promises).then resolve
    stream.on 'end', ->
      Promise.all(auc_promises).then () ->
        update_etps ->
          update_statuses ->
            update_regions ->
              tempConnection.db.dropDatabase()
              log.info 'Complete converting'
              cb()