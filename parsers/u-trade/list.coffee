cheerio         = require 'cheerio'
Sync            = require 'sync'
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
      trades = []
      etpUrl = etp.href.match(host)[0]
      rows = $('tr[onclick *= "/trade/view/purchase/general.html?id="], tr[onclick *= "location.href=\'generalView?id="]')
      if rows.length is 0
        rows = $('a[href *= "/trade/view/purchase/general.html?id="]')
        for row in rows
          rel = $(row).attr('href')
          url = etpUrl + rel
          url = url.replace '://www.', '://'
          num = $(row).parent().parent().find('td:nth-child(1)').text()
          trades.push
            etp: etp
            url: url.replace '//www.', '//'
            downloader: 'request'
            parser: 'u-trade/trade'
            queue: config.tradeHtmlQueue
            number: num
      else
        for row in rows
          func = $(row).attr('onclick')
          rel = func.match(/window.location=\'(\/trade\/view\/purchase\/general.html\?id=\d+)\'/i)?[1]
          unless rel? then rel = func.match(/^location\.href=(.+)$/)[1]
          url = etpUrl + rel
          url = url.replace '://www.', '://'
          num = $(row).find('td:nth-child(1)').text()
          trades.push
            etp: etp
            url: url.replace '//www.', '//'
            downloader: 'request'
            parser: 'u-trade/trade'
            queue: config.tradeHtmlQueue
            number: num
      result = []
      for trade in trades
        if redis.check.sync(null, trade.url)
          result.push trade
      cb null, result
    catch e then cb e