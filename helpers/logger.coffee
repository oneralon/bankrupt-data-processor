bunyan     = require 'bunyan'
formatOut  = require('bunyan-format')({outputMode: 'short'})

module.exports = (name) ->
  bunyan.createLogger
    name: name
    streams: [
      level: 'error'
      path: __dirname + '/../logs/error.log'
    ,
      level: 'info'
      path: __dirname + '/../logs/info.log'
    ,
      level: 'error'
      stream: formatOut
    ,
      level: 'info'
      stream: formatOut
    ]