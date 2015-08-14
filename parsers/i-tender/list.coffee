Sync            = require 'sync'
cheerio         = require 'cheerio'
_               = require 'lodash'

redis     = require '../../helpers/redis'
logger    = require '../../helpers/logger'
log       = logger  'I-TENDER LIST PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

module.exports = (html, etp, cb) ->
  Sync =>
    try
      $ = cheerio.load(html)
      rows = $("[id*='ctl00_ctl00_MainContent'] > tbody > tr.gridRow")
      log.info "Rows #{rows.length}"
      trades = []
      for row in rows
        trade = $(row).find("td.gridAltColumn a[class*='purchase-type-']")
        tradeUrl = etp.href.match(host)[0] + trade.attr('href')
        tradeUrl += '/' unless /\/$/.test tradeUrl
        tradeNum = trade.text()
        if _.where(trades, {url: tradeUrl}).length is 0
          trades.push
            etp: etp
            url: tradeUrl
            downloader: 'request'
            parser: 'i-tender/trade'
            queue: config.tradeHtmlQueue
            number: tradeNum
      result = []
      for trade in trades
        if redis.check.sync(null, trade.url)
          result.push trade
      cb null, result
    catch e then cb e