amqp            = require 'amqplib'
Sync            = require 'sync'
request         = require 'request'
config          = require '../config'
logger          = require '../helpers/logger'
log             = logger  'REQUEST DOWNLOADER'

module.exports = (url, cb) ->
  Sync =>
    try
      while not data? or data.length is 0 or typeof data is 'undefined'
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
        'Content-Type': 'text/html; charset=utf-8'
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  }).on 'error', (err) -> cb err
  .on 'response', (res) ->
    res.setEncoding('utf8')
    data = ''
    res.on 'end', () => cb null, data
    res.on 'data', (chunk) => data += chunk
  .on 'timeout', -> cb "Reset by timeout #{url}"