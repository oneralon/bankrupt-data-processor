Sync       = require 'sync'
Promise    = require 'promise'

сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/trade'
Trade     = сonnection.model 'Trade'

module.exports = (grunt) ->
  grunt.registerTask 'migration:dublicates', ->
    done = @async()
    Trade.distinct('url').exec (err, urls) ->
      Sync =>
        try
          for url in urls
            uniq.sync null, url
            console.log url
          done()
        catch e then done e

uniq = (url, cb) ->
  save = []
  turl = url.replace '://www.', ''
  rurl = new RegExp url.replace '://www.', '(://www.)?'
  Trade.find({url:rurl}).populate('lots').exec (err, trades) ->
    if trades.length is 1 then cb()
    else
      i = 1
      while i < trades.length
        save.push new Promise (resolve) ->
          lots = []
          for lot in trade[i].lots
            lots.push new Promise (resolve) -> lot.remove resolve
          Promise.all(lots).then -> resolve()
      Promise.all(save).then -> cb()