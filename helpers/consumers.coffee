forever    = require 'forever-monitor'
logger     = require '../helpers/logger'
log        = logger  'CONSUMERS FOREVER'

consumers  = []

module.exports.start = ()->
  log.info 'Start all consumers'
  consumers = []
  consumers.push forever.start(['coffee', './consumers/lists-html.coffee'],  {max: 1})
  consumers.push forever.start(['coffee', './consumers/lots-url.coffee'],    {max: 1})
  consumers.push forever.start(['coffee', './consumers/trades-html.coffee'], {max: 1})

module.exports.stop = ()->
  for child in consumers
    child.stop()
  log.info 'Stop all consumers'
