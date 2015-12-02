forever    = require 'forever-monitor'
Sync       = require 'sync'
logger     = require '../helpers/logger'
log        = logger  'COLLECTOR FOREVER'

module.exports = (etp, timeout, recollect, cb) ->
  Sync =>
    try
      code = proceed.sync null, etp, timeout, recollect
      while code isnt 0
        code = proceed.sync null, etp, timeout, recollect
      cb()
    catch e
      log.error e
      cb e

proceed = (etp, timeout, recollect, cb)->
  collector = forever.start([
    'coffee', "./collectors/#{etp.platform}.coffee",
    '--name', etp.name, '--href', etp.href, '--platform', etp.platform, '--recollect', recollect],
  {max: 1})
  if timeout > 0
    watchdog = setTimeout( ->
      clearTimeout watchdog
      log.info "Stop collecting by timer"
      collector.stop()
      cb(null, 0)
    , timeout) if timeout?
    collector.on 'exit:code', (code) ->
      clearTimeout watchdog if watchdog?
      cb(null, code)
  else
    collector.on 'exit:code', (code) ->
      cb(null, code)
