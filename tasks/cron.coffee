mongoose   = require 'mongoose'
Sync       = require 'sync'
exec       = require('child_process').execSync
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
    exec 'sudo service mongodb restart'
    exec 'pkill -9 -f \'SCREEN grunt production\''
    exec 'cd ~/projects/bankrupt-server && screen grunt production'
    console.log "Reload server done"
    done()

  grunt.registerTask 'cron:reload-consumers', ->
    console.log "Reloading consumers..."
    exec 'sudo service rabbitmq-server restart'
    exec 'sudo service redis-server restart'
    exec 'pkill -9 -f \'SCREEN coffee consumers/lists-html.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/trades-url.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/trades-html.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/trades-json.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/lot-url.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/lot-html.coffee\''
    exec 'pkill -9 -f \'SCREEN coffee consumers/lot-json.coffee\''
    exec 'cd /opt/bdp && screen coffee consumers/lists-html.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/trades-url.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/trades-html.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/trades-json.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/lot-url.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/lot-html.coffee'
    exec 'cd /opt/bdp && screen coffee consumers/lot-json.coffee'
    console.log "Done"
    done = @async()