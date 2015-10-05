Sync      = require 'sync'
redis     = require '../../helpers/redis'
logger    = require '../../helpers/logger'
log       = logger  'SBERBANK-AST LIST PARSER'
config    = require '../../config'

module.exports = (content, etp, cb) ->
  trades = JSON.parse content
  result = []
  Sync =>
    try
      for trade in trades
        if redis.check.sync(null, trade.url)
          result.push
            etp: etp
            url: trade.url.replace '//www.', '//'
            downloader: 'request'
            parser: 'sberbank-ast/trade'
            queue: config.tradeHtmlQueue
            number: trade.number
      cb null, result
    catch e then cb e