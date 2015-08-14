forever    = require 'forever-monitor'
Sync       = require 'sync'
logger     = require '../helpers/logger'
log        = logger  'COLLECTOR FOREVER'

timer = (timeout, cb) ->
  return setTimeout ->
    log.info "Stop collecting by timer"
    cb()
  , timeout

module.exports = (etp, timeout, cb) ->
  Sync =>
    try
      watchdog = timer(timeout, cb) if timeout?
      code = proceed.sync null, etp
      clearTimeout(watchdog) if watchdog?
      while code isnt 0
        watchdog = timer(timeout, cb) if timeout?
        code = proceed.sync null, etp
        clearTimeout(watchdog) if watchdog?
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