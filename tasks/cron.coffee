mongoose   = require 'mongoose'
Sync       = require 'sync'
Promise    = require 'promise'
moment     = require 'moment'
sh         = require 'child_process'
collector  = require '../helpers/collector'
redis      = require '../helpers/redis'
amqp       = require '../helpers/amqp'
diffpatch  = require '../helpers/diffpatch'
mongo      = require '../helpers/mongo'
config     = require '../config'
host       = /^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/lot'
Lot       = сonnection.model 'Lot'
require '../models/trade'
Trade     = сonnection.model 'Trade'

module.exports = (grunt) ->
  grunt.registerTask 'cron:present', ->
    console.log 'Update present field' 
    done = @async()
    Lot.update {present:true, last_event:{$lte:new Date()}}, {$set:{present:false}}, {multi:1}, (err, result) ->
      done(err) if err?
      console.log 'Updated: ' + result.nModified
      done()

  grunt.registerTask 'cron:recollect', ->
    console.log "Start updating of #{config.etps.length} sources" 
    done = @async()
    Sync =>
      try
        for etp in config.etps
          redis.clear.sync null
          amqp.init.sync null
          collector.sync null, etp, config.incUpdTime
        log.info "Complete updating of #{config.etps.length} sources"
        done()
      catch e
        log.error e
        done(e)

  grunt.registerTask 'cron:reload-server', ->
    console.log "Reloading mongo and services..."
    done = @async()
    sh.execSync 'sudo service mongodb restart'
    console.log "Reload mongo done"
    done()

  grunt.registerTask 'cron:reload-consumers', ->
    console.log "Reloading consumers..."
    done = @async()
    sh.execSync 'sudo service rabbitmq-server restart'
    sh.execSync 'sudo service redis-server restart'
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/lists-html.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/trades-url.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/trades-html.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/trades-json.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/lots-url.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/lots-html.coffee\''
    sh.execSync 'pkill -9 -f \'node /usr/local/bin/coffee /opt/bdp/consumers/lots-json.coffee\''
    sh.spawn 'coffee', ['/opt/bdp/consumers/lists-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']} 
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lots-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lots-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lots-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    console.log "Done"
    done()

  grunt.registerTask 'cron:old', ->
    console.log "Update old lots"
    done = @async()
    date = moment().subtract(3, 'hour')
    query =
      status: $in: ["Идут торги", "Извещение опубликовано", "Не определен", "Прием заявок"]
      updated: { $exists: true, $lt: date }
    perPage = 1000
    proceed_range = (skip, cb) ->
      lot_promises = []
      Lot.find(query).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        if not lots? or lots.length is 0 then cb(null, false)
        console.log "Skip: #{skip}\t\t\t\tLots: #{lots.length}"
        Sync =>
          try
            for lot in lots
              if lot.trade? and lot.trade._id?
                if lot.url is lot.trade.url
                  queue = config.tradeUrlsQueue 
                  parser = lot.trade.etp.platform + '/' + 'trade'
                else
                  queue = config.lotsUrlsQueue
                  parser = lot.trade.etp.platform + '/' + 'lot'
                downloader = if /sberbank/.test lot.trade.etp.platform then 'request-sber' else 'request'
                r = new RegExp(lot.url.match(host)[2])
                etp = config.etps.filter( (t) ->
                  r.test t.href
                )?[0]
                amqp.publish.sync null, queue, '', headers:
                  etp: etp
                  downloader: downloader
                  url: lot.url
                  queue: queue.replace 'Urls', 'Html'
                  parser: parser
              else
                console.log "Remove lot with empty trade -- #{lot._id}"
                lot.remove.sync null
            cb(null, true)
          catch e then done(e)
    Sync =>
      try
        res = true
        current = 0
        while res
          res = proceed_range.sync null, current
          current += perPage
        done()
      catch e then done(e)

  grunt.registerTask 'cron:events', ->
    console.log "Update last event lots"
    done = @async()
    date = moment().subtract(3, 'hour')
    query =
      status: $in: ["Идут торги", "Извещение опубликовано", "Не определен", "Прием заявок"]
      $or: [
        present: true, last_date: $lte: new Date()
      ,
        present: $exists: false
      ,
        last_event: $exists: false
      ,
        last_event: null
      ]
    perPage = 1000
    proceed_range = (skip, cb) ->
      lot_promises = []
      Lot.find(query).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        if not lots? or lots.length is 0 then cb(null, false)
        console.log "Skip: #{skip}\t\t\t\tLots: #{lots.length}"
        Sync =>
          try
            for lot in lots
              if lot.trade? and lot.trade._id?
                diffpatch.patch lot, diffpatch.diff(lot, diffpatch.intervalize(lot, lot.trade), Lot)
                lot.save.sync null
              else
                console.log "Remove lot with empty trade -- #{lot._id}"
                save lot_promises, lot
            cb(null, true)
          catch e then done(e)
    Sync =>
      try
        res = true
        current = 0
        while res
          res = proceed_range.sync null, current
          current += perPage
        done()
      catch e then done(e)

save = (container, item) ->
  container.push new Promise (resolve) -> 
    item.last_event = new Date(item.last_event)
    console.log item.url
    item.save()