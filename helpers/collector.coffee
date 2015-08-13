forever    = require 'forever-monitor'
Sync       = require 'sync'
logger     = require '../helpers/logger'
log        = logger  'COLLECTOR FOREVER'

module.exports.collect = (etp, cb) ->
  Sync =>
    try
      code = proceed.sync null, etp
      while code isnt 0
        code = proceed.sync null, etp
      cb()
    catch e
      log.error e
      cb e

proceed = (etp, cb)->
  collector = forever.start([
    'coffee', "./collectors/#{etp.platform}.coffee",
    '--name', etp.name, '--href', etp.href, '--platform', etp.platform],
  {max: 1})
  collector.on 'exit:code', (code) ->
    cb(null, code)