Sync            = require 'sync'
needle          = require 'needle'
cheerio         = require 'cheerio'

options =
  proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true

module.exports = (url, cb) ->
  Sync =>
    try
      while typeof data is 'undefined' or not data? or data.length < 1000
        data = get.sync null, url
      cb null, data, {}
    catch e then cb e

get = (url, cb) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  needle.get url, options, (err, resp, body) -> 
    cb() if err? or not body?
    if typeof body isnt 'undefined'
      $ = cheerio.load body
      xml = $('#xmlData').val()
      if xml? then cb(null, xml) else cb()
    else cb()
