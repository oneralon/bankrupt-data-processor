phantom   = require 'node-phantom-simple'
etag      = require 'etag'
cheerio   = require 'cheerio'
Sync      = require 'sync'

argv      = require('optimist').argv
amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
request   = require '../downloaders/request'
log       = logger  'U-TRADE LIST COLLECTOR'
config    = require '../config'
etp       = { name: argv.name, href: argv.href, platform: argv.platform }

Sync =>
  try
    if /m\-ets/.test etp.href
      params = [
        '?lots=&r_num=О&debtor=&org=&arb=&stat=3'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=4'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=5%2C6'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=71'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=72'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=8'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=10'
        '?lots=&r_num=О&debtor=&org=&arb=&stat=12'
      ]
    else
      params = [
        '?processStatus=BID_SUBMISSION'
        '?processStatus=BEFORE_TRADE'
        '?processStatus=ACTIVE'
        '?processStatus=AFTER_TRADE'
        '?processStatus=CANCELED'
      ]
    log.info "Start collecting #{etp.name}"
    for status in params
      href = etp.href + status
      last = parseInt(redis.get.sync(null, href) or '1')
      resp = request.sync null, href
      $ = cheerio.load resp[0]
      links = $("a[href *= '/etp/trade/list.html'], a[href*='r_num']")
      if links.length is 0 then pages = 1
      else pages = parseInt $(links[links.length - 1]).attr('href').match(/page=(\d+)/i)?[1] or 1
      for page in [last..pages]
        log.info "Download page #{page} of #{pages}"
        if /\?/.test etp.href then url = href + "&page=#{page}"
        else url = href + "?page=#{page}"
        resp = request.sync null, url
        amqp.publish.sync null, config.listsHtmlQueue, new Buffer(resp[0], 'utf8'),
          headers:
            parser: 'u-trade/list'
            etp: etp
        redis.set.sync null, etp.href, page.toString()
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1