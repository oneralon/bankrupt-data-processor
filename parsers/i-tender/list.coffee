Sync            = require 'sync'
cheerio         = require 'cheerio'

redis     = require '../../helpers/redis'
logger    = require '../../helpers/logger'
log       = logger  'I-TENDER LIST PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

module.exports = (html, etp, cb) ->
  Sync =>
    try
      result =
        trades: []
        lots: []
      $ = cheerio.load(html)
      rows = $("[id*='ctl00_ctl00_MainContent'] > tbody > tr.gridRow")
      log.info "Rows #{rows.length}"
      for row in rows
        lot = $(row).find("td.gridColumn a.tip-lot")
        lotUrl = etp.url.match(host)[0] + lot.attr('href')
        lotUrl += '/' unless /\/$/.test lotUrl
        lotName = lot.text()
        trade = $(row).find("td.gridAltColumn a[class*='purchase-type-']")
        tradeUrl = etp.url.match(host)[0] + trade.attr('href')
        tradeUrl += '/' unless /\/$/.test tradeUrl
        tradeNum = trade.text()
        if typeof lotUrl is 'undefined'
          log.error "LOT: #{lotUrl}"
        else result.lots.push
          etp: etp
          url: lotUrl
          tradeUrl: tradeUrl
          downloader: 'request'
          parser: 'i-tender/lot'
          queue: config.lotsHtmlQueue
        if redis.check.sync(null, tradeUrl)
          result.trades.push
            etp: etp
            url: tradeUrl
            downloader: 'request'
            parser: 'i-tender/trade'
            queue: config.tradeHtmlQueue
            number: tradeNum
      cb null, result
    catch e then cb e