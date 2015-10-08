Sync            = require 'sync'
request         = require 'request'
Phantom         = require 'node-phantom-simple'

module.exports = (url, cb) ->
  phantom = null
  page = null
  Sync =>
    try
      phantom = Phantom.create.sync null
      phantom.onError = (err) ->
        log.info err
        cb err
      page = phantom.createPage.sync null
      res = page.open.sync null, url
      cb "Non 200 code page" unless res is 'success'
      xml = page.evaluate.sync null, -> $('#xmlData').val()
      phantom.exit -> cb(null, xml)
    catch e then phantom.exit -> cb e