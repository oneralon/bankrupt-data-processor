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
      while typeof data is 'undefined' or not data? or data.length is 0
        data = get.sync null, url
      cb null, data
    catch e then cb e

get = (url, cb) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  request.get(url,{
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
    if /Windows\-1251/i.test encoding
      encoding = 'win1251'
    else
      encoding = 'utf8'
      res.setEncoding encoding
    data = ''
    res.on 'end', () => cb null, data
    res.on 'data', (chunk) =>
      if encoding is 'win1251'
        data += iconv.decode chunk, encoding
      else data += chunk
  .on 'timeout', -> cb()