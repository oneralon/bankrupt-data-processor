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
    log.info "Start collecting #{etp.name}"
    last = parseInt redis.get.sync(null, etp.href) or '1'
    html = request.sync null, etp.href
    $ = cheerio.load html
    links = $("a[href *= '/etp/trade/list.html']")
    if links.length is 0 then pages = 1
    else pages = parseInt $(links[links.length - 1]).attr('href').match(/page=(\d+)/i)[1]
    for page in [last..pages]
      log.info "Download page #{page} of #{pages}"
      if /\?/.test etp.href then url = etp.href + "&page=#{page}"
      else url = etp.href + "?page=#{page}"
      html = request.sync null, url
      amqp.publish.sync null, config.listsHtmlQueue, new Buffer(html, 'utf8'),
        headers:
          parser: 'u-trade/list'
          etp: etp
      redis.set.sync null, etp.href, page.toString()
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1