mongoose        = require 'mongoose'
moment          = require 'moment'
fs              = require 'fs'
_               = require 'lodash'
Promise         = require 'promise'

config          = require "./config"
diffpatch       = require './helpers/diffpatch'
regionize       = require './helpers/regionize'

require './models/trade'
require './models/lot'

tempConnection  = mongoose.createConnection "mongodb://localhost/#{config.tmpDB}"
prodConnection  = mongoose.createConnection "mongodb://localhost/#{config.db}"

Trade     = prodConnection.model 'Trade'
Lot       = prodConnection.model 'Lot'



console.log 'Convert temp db to production db'
tempConnection.collection('auctions').find (err, cursor) ->
  auc_promises = []
  stream = cursor.stream()
  stream.on 'data', (auc) ->
    if auc.number.length > 10
      console.log auc.number
      console.log auc.url
    auc_promises.push new Promise (resolve) ->
      Trade.findOne({number: auc.number}).populate('lots').exec (err, trade) ->
        save_promises = []
        unless trade?
          trade = new Trade()
          for k, v of auc
            unless v instanceof Object
              trade[k] = v or undefined
          for auc_lot in auc.lots
            auc_lot.region = regionize auc_lot.region
            console.log auc_lot.region
            lot = new Lot()
            for k, v of auc_lot
              if v?
                lot[k] = v
              else
                lot[k] = undefined
            lot.trade = trade._id
            lot.save()
            trade.lots.push lot
          trade.owner = auc.owner
          trade.debtor = auc.debtor
          trade.etp = auc.etp
          trade.documents = auc.documents
          save_promises.push new Promise (resolve) ->
            trade.save resolve
        else
          diff = diffpatch.diff trade, auc, Trade
          diffpatch.patch trade, diff
          trade.owner = auc.owner
          trade.debtor = auc.debtor
          trade.etp = auc.etp
          trade.documents = auc.documents
          save_promises.push new Promise (resolve) ->
            trade.save resolve
          for auc_lot in auc.lots
            auc_lot.region = regionize auc_lot.region
            console.log auc_lot.region
            lot = _.where(trade.lots, {number: Number auc_lot.number})[0]
            if lot?
              diff = diffpatch.diff lot, auc_lot, Lot
              # console.log diff
              diffpatch.patch lot, diff
              lot.intervals = auc_lot.intervals
              lot.documents = auc_lot.documents
              lot.tagInputs = auc_lot.tagInputs
              lot.tags      = auc_lot.tags

              save_promises.push new Promise (resolve) ->
                lot.save resolve
            else
              console.log "Trade #{trade.number} has no lot #{auc_lot.number}"
              lot = new Lot()
              for k, v of auc_lot
                if v?
                  lot[k] = v
                else
                  lot[k] = undefined
              lot.trade = trade._id
              save_promises.push new Promise (resolve) ->
                lot.save resolve
              trade.lots.push lot
        Promise.all(save_promises).then resolve

  stream.on 'end', ->
    console.log 'end'
    Promise.all(auc_promises).then () ->
      update_etps ->
        update_statuses ->
          update_regions ->
            prodConnection.close()
            tempConnection.db.dropDatabase()
            tempConnection.close()
            console.log 'converted'

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