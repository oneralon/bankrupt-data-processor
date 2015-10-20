mongoose   = require 'mongoose'
Sync       = require 'sync'
Promise    = require 'promise'
sh         = require 'child_process'
collector  = require '../helpers/collector'
redis      = require '../helpers/redis'
amqp       = require '../helpers/amqp'
config     = require '../config'
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"

require '../models/lot'
Lot       = сonnection.model 'Lot'

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
    console.log "Reloading server and services..."
    done = @async()
    sh.execSync 'sudo service mongodb restart'
    sh.execSync 'pkill -9 -f \'SCREEN grunt production\''
    sh.execSync 'cd ~/projects/bankrupt-server && screen grunt production'
    console.log "Reload server done"
    done()

  grunt.registerTask 'cron:reload-consumers', ->
    console.log "Reloading consumers..."
    done = @async()
    sh.execSync 'sudo service rabbitmq-server restart'
    sh.execSync 'sudo service redis-server restart'
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/lists-html.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/trades-url.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/trades-html.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/trades-json.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/lot-url.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/lot-html.coffee\''
    sh.execSync 'pkill -9 -f \'SCREEN coffee consumers/lot-json.coffee\''
    sh.spawn 'coffee', ['/opt/bdp/consumers/lists-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']} 
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/trades-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lot-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lot-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    sh.spawn 'coffee', ['/opt/bdp/consumers/lot-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    console.log "Done"
    done()

  grunt.registerTask 'cron:old', ->
    console.log "Update old lots"
    done = @async()
    date = moment().subtract(2, 'day')
    query =
      status: $in: ["Идут торги", "Извещение опубликовано", "Не определен", "Прием заявок"]
      updated: { $exists: true, $lt: date }
    perPage = 1000
    proceed_range = (skip, cb) ->
      lot_promises = []
      Lot.find(query).skip(skip).limit(perPage).populate('trade').exec (err, lots) ->
        cb(err) if err?
        if not lots? or lots.length is 0 then cb()
        console.log "Skip: #{skip}\t\t\t\tLots: #{lots.length}"
        for lot in lots
          if lot.trade? and lot.trade._id?
            if lot.url is trade.url
              queue = config.tradeUrlsQueue 
              parser = lot.trade.etp.platform + '/' + 'trade'
            else
              queue = config.lotsUrlsQueue
              parser = lot.trade.etp.platform + '/' + 'lot'
            downloader = if /sberbank/.test lot.trade.etp.platform then 'request-sber' else 'request'
            lot_promises.push new Promise (resolve) ->
              amqp.publish queue, null, headers:
                etp: lot.trade.etp
                downloader: downloader
                url: lot.url
                queue: queue.replace 'Urls', 'Html'
                parser: parser
              , resolve
          else
            console.log "Remove lot with empty trade -- #{lot._id}"
            lot_promises.push new Promise (resolve) -> lot.remove(resolve)
        Promise.all(lot_promises).catch(cb).then -> proceed_range(skip + perPage, cb)
    proceed_range 0, ->
      console.log "Done"
      done()