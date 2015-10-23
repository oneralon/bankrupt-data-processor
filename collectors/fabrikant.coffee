needle    = require 'needle'
Sync      = require 'sync'
cheerio   = require 'cheerio'
amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
log       = logger  'FABRIKANT LIST COLLECTOR'
config    = require '../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

options =
  # proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true
  open_timeout: 120000

argv = require('optimist').argv
etp = {name: argv.name, href: argv.href, platform: argv.platform}

collect = (etp, cb) ->
  Sync =>
    try
      current = parseInt(redis.get.sync null, etp.href) or 1
      result = proceed.sync null, current, etp
      while result isnt null
        current += 1
        result = proceed.sync null, current, etp
      log.info "Complete collecting #{etp.url}"
      cb()
    catch e then cb e

proceed = (number, etp, cb) ->
  Sync =>
    try
      resp = needle.get.sync null, etp.href + '&page=' + number, options
      $ = cheerio.load resp[1]
      trades = parseInt $('.Search-result-count > span').text().trim()
      pages = Math.round(trades / 10) + 1
      if number > pages then cb()
      rows = $('.Search-result-item')
      urls = []
      result = []
      $('.Search-result-item').each ->
        num = $(@).find('div.Search-item-option:contains("№")').text().trim().match(/\d+/)[0]
        url = $(@).find('.Search-item-option > a[target!=_blank]').first().attr('href')
        url = etp.href.match(host)[0] + url
        url = url.replace '://www.', '://'
        if urls.indexOf(url) is -1
          urls.push url
          result.push url: url, number: num
      amqp.publish.sync null, config.listsHtmlQueue, new Buffer(JSON.stringify(result), 'utf8'),
        headers:
          parser: 'fabrikant/list'
          etp: etp
      log.info "Complete page #{number} of #{pages} pages"
      redis.set.sync null, etp.href, number.toString()
      cb(null, rows)
    catch e then cb e

collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0