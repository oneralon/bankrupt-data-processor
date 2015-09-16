mongoose   = require 'mongoose'
Sync       = require 'sync'
Promise    = require 'promise'
moment     = require 'moment'
_          = require 'lodash'
config     = require '../config'
regionize  = require './regionize'
diffpatch  = require './diffpatch'
status     = require './status'
logger     = require './logger'
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

module.exports.trade_remove = (trade_url, cb) ->
  Trade.findOne({url: trade_url}).populate('lots').exec (err, trade) ->
    unless trade? then cb()
    promises = []
    for lot in trade.lots
      promises.push new Promise (resolve) -> lot.remove(resolve)
    Promise.all(promises).then -> trade.remove(cb)

module.exports.lot_remove = (query, cb) ->
  Lot.findOne(query).populate('trade').exec (err, lot) ->
    unless lot? then cb()
    lot.trade.lots = lot.trade.lots.filter (i) -> i.toString() isnt lot._id.toString()
    lot.trade.save -> lot.remove(cb)

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

module.exports.updateLot = (alot, cb) ->
  alot.url = alot.url.replace '//www.', '//'
  rurl = new RegExp alot.url.replace('//', '//(www.)')
  Lot.find({url: alot.url, number: alot.number}).populate('trade').exec (err, lots) ->
    if lots.length > 0
      dublicates = []
      lot = lots[0]
      if lots.length > 1
        for i in [1..lots.length-1]
          rlot = lots[i]
          lot.trade.lots = lot.trade.lots.filter (i) -> i.toString() isnt rlot._id.toString()
          dublicates.push new Promise (resolve) -> rlot.remove(resolve)
      diff = diffpatch.diff lot, alot, Lot
      diffpatch.patch lot, diff
      lot.intervals = alot.intervals
      lot.documents = alot.documents
      lot.tagInputs = alot.tagInputs
      lot.tags      = alot.tags
      lot.region    = lot.trade.region
      lot.updated = new Date()
      if lots.length > 1
        log.info "Updated #{lot.url} with #{lots.length - 1} dublicates"
        Promise.all(dublicates).then -> lot.trade.save -> lot.save(cb)
      else
        log.info "Updated #{lot.url}"
        lot.save(cb)
    else
      log.error "Not fount lot #{alot.url}, num: #{alot.number}"

module.exports.update = (auction, cb) ->
  if not auction.region? or auction.region is 'Не определен'
    auction.region = regionize(auction)
  auction.url = auction.url.replace '//www.', '//'
  for lot in auction.lots
    lot.url = lot.url.replace '//www.', '//'
    lot.region = auction.region if not lot.region or lot.region is 'Не определен'
    if lot.status or lot.status is '' then lot.status = status lot.status else lot.status = 'Не определен'
  save = []
  regurl = new RegExp(auction.url.replace(/https?:\/\/(www.)?/, ''))
  Trade.findOne({url: regurl}).populate('lots').exec (err, trade) ->
    unless trade?
      log.info "NEW Trade #{auction.url}"
      trade = new Trade()
      diffpatch.trade trade, auction
      for alot in auction.lots
        unless alot.url? then alot.url = trade.url
        lot = new Lot()
        diffpatch.lot lot, alot
        lot.trade = trade._id
        lot.region = trade.region
        lot.updated = new Date()
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
        if alot.status isnt ''
          unless alot.url? then alot.url = trade.url
          lots = _.where(trade.lots, {url: alot.url, number: alot.number})
          if lots.length > 0
            lot = lots[0]
            dublicates = []
            if lots.length > 1
              for i in [1..lots.length-1]
                rlot = lots[i]
                trade.lots = trade.lots.filter (i) -> i._id.toString() isnt rlot._id.toString()
                dublicates.push new Promise (resolve) -> rlot.remove(resolve)
            diff = diffpatch.diff lot, alot, Lot
            diffpatch.patch lot, diff
            lot.intervals = alot.intervals
            lot.documents = alot.documents
            lot.tagInputs = alot.tagInputs
            lot.tags      = alot.tags
            lot.region    = trade.region
            lot.updated = new Date()
            if lots.length > 1 then Promise.all(dublicates).then -> save.push new Promise (resolve) -> lot.save resolve
            else save.push new Promise (resolve) -> lot.save resolve
          else
            lot = new Lot()
            lot.trade = trade._id
            lot.region = trade.region
            diffpatch.lot lot, alot
            lot.updated = new Date()
            trade.lots.push lot
            save.push new Promise (resolve) -> lot.save resolve
        else
          console.log alot.url
          console.log alot
    Promise.all(save).then () ->
      trade.updated = new Date()
      trade.save cb