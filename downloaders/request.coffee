amqp            = require 'amqplib'
Sync            = require 'sync'
request         = require 'request'
iconv           = require 'iconv-lite'
config          = require '../config'
logger          = require '../helpers/logger'
log             = logger  'REQUEST DOWNLOADER'

module.exports = (url, cb) ->
  Sync =>
    try
      while typeof data is 'undefined' or not data? or data.length < 40000
        data = get.sync null, url
      cb null, data
    catch e then cb e

get = (url, cb) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  request.get(url, {
    options:
      headers:
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
        'Accept-Language': 'en-US,en;q=0.8'
        'Cache-Control': 'max-age=0'
        'Accept-Charset': 'utf-8'
        'Content-Type': 'text/html; charset=utf-8'
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  }).on 'error', (err) -> cb()
  .on 'response', (res) ->
    encoding = res.headers['content-type'].match(/charset=(.+)/i)[1]
    encoding = if /Windows\-1251/i.test(encoding) then 'win1251' else 'utf8'
    chunks = []
    res.on 'end', () -> cb null, iconv.decode Buffer.concat(chunks), encoding
    res.on 'data', (chunk) -> chunks.push chunk
  .on 'timeout', -> cb()