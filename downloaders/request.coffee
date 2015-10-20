amqp            = require 'amqplib'
Sync            = require 'sync'
needle          = require 'needle'
iconv           = require 'iconv-lite'
config          = require '../config'
logger          = require '../helpers/logger'
log             = logger  'REQUEST DOWNLOADER'
options =
  proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true
  open_timeout: 120000

module.exports = (url, cb) ->
  Sync =>
    try
      while typeof data is 'undefined' or not data? or data.length < 10000
        console.log data?.length
        data = get.sync null, url
      cb null, data
    catch e then cb e

get = (url, cb) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  needle.get url, options, (err, resp, body) ->
    unless err? and resp?.statusCode isnt 200
      encoding = resp.headers['content-type']?.match(/charset=(.+)/i)?[1]
      encoding = if encoding? and /Windows\-1251/i.test(encoding) then 'win1251' else 'utf8'
      if body? then cb null, iconv.decode(new Buffer(resp.raw), encoding) else cb()
    else cb()
