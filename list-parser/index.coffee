config     = require './../config'
parser     = require './parser'
log        = require('./../helpers/logger')()

parser.start (err) ->
  if err?
    log.error err
    process.exit(1)
  else process.exit(0)