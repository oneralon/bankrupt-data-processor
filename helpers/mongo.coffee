mongoose   = require 'mongoose'
Sync       = require 'sync'
Promise    = require 'promise'
moment     = require 'moment'
_          = require 'lodash'
config     = require '../config'
regionize  = require './regionize'
diffpatch  = require './diffpatch'
logger     = require '../helpers/logger'
log        = logger  'MONGODB'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/trade'
require '../models/lot'
require '../models/tag'

Trade     = сonnection.model 'Trade'
Lot       = сonnection.model 'Lot'

module.exports.insert = (table, item, cb) ->
  mongoose.connect "mongodb://localhost/#{config.tmpDB}"
  collection = mongoose.connection.collection table
  collection.insert item, (err, res) ->
    cb err if err?
    log.info "Inserted to DB: #{table}"
    mongoose.connection.close()
    cb null, res

module.exports.update_etps = (cb) ->
  Trade.distinct 'etp.name', (err, result) ->
    сonnection.collection('etps').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, etps) ->
      unless _.isEqual(result.sort(), etps?.list?.sort())
        сonnection.collection('etps').insert
          list: result
          _v: etps?._v+1 or 0
        , cb
      else cb()

module.exports.update_statuses = (cb) ->
  Lot.distinct 'status', (err, result) ->
    сonnection.collection('statuses').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, statuses) ->
      unless _.isEqual(result.sort(), statuses?.list?.sort())
        сonnection.collection('statuses').insert
          list: result
          _v: statuses?._v+1 or 0
        , cb
      else cb()

module.exports.update_regions = (cb) ->
  Lot.distinct 'region', (err, result) ->
    сonnection.collection('regions').findOne { $query: {}, $orderby: { '_v' : -1 } , $limit: 1}, (err, regions) ->
      unless _.isEqual(result.sort(), regions?.list?.sort())
        сonnection.collection('regions').insert
          list: result
          _v: regions?._v+1 or 0
        , cb
      else cb()

module.exports.update = (auction, cb) ->
  if not auction.region or auction.region is 'Не определен'
    auction.region = regionize(auction)
  for lot in auction.lots
    lot.region = auction.region if not lot.region or lot.region is 'Не определен'
  save = []
  Trade.findOne({url: auction.url}).populate('lots').exec (err, trade) ->
    unless trade?
      log.info "NEW Trade #{auction.url}"
      trade = new Trade()
      diffpatch.trade trade, auction
      for alot in auction.lots
        if alot.url?
          lot = new Lot()
          diffpatch.lot lot, alot
          lot.trade = trade._id
          lot.region = trade.region
          trade.lots.push lot
          save.push new Promise (resolve) -> lot.save resolve
    else
      log.info "UPD Trade #{auction.url}"
      diff = diffpatch.diff trade, auction, Trade
      diffpatch.patch trade, diff
      trade.owner     = auction.owner
      trade.debtor    = auction.debtor
      trade.etp       = auction.etp
      trade.documents = auction.documents
      auction.lots    = auction.lots or []
      for alot in auction.lots
        if alot.url?
          lot = _.where(trade.lots, {url: alot.url})[0]
          if lot?
            diff = diffpatch.diff lot, alot, Lot
            diffpatch.patch lot, diff
            lot.intervals = alot.intervals
            lot.documents = alot.documents
            lot.tagInputs = alot.tagInputs
            lot.tags      = alot.tags
            lot.region    = trade.region
            save.push new Promise (resolve) -> lot.save resolve
          else
            lot = new Lot()
            lot.trade = trade._id
            lot.region = trade.region
            diffpatch.lot lot, alot
            trade.lots.push lot
            save.push new Promise (resolve) -> lot.save resolve
    Promise.all(save).then () ->
      trade.updated = new Date()
      trade.save cb