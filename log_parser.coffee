fs     = require 'fs'
moment = require 'moment'

parse = (line) ->
  result = line.match /(\d+\.\d+\.\d+\.\d+)\s\-\s\[(.+?)\]\s(.*?)\s\"(.+?)\"\s(\d+)\s(\d+)/
  code = if /HTTP/.test result[4] then result[5] else result[4]
  unless result?
    console.log line
  {
    time: moment(result[2], 'D/MMM/YYYY:HH:mm:ss Z').toDate()
    code: parseInt code
  }

fs.readFile 'nginx.log', (err, content) ->
  text = content.toString()
  lines = text.split('\n')
  start = interval = parse(lines[0]).time
  code = parse(lines[0]).code
  end = parse(lines[lines.length-2]).time
  result = {}
  console.log "Log from #{start} to #{end}"
  lines.forEach (line) ->
    if line isnt ''
      line = parse line
      if code isnt line.code
        result[code] = result[code] or 0
        result[code] += line.time - interval
        interval = line.time
        code = line.code
  up = 0
  down = 0
  for k, v of result
    if /^[1234]/.test k then up += v
    else down += v
  total = up + down
  console.log "Time\t--\tup: #{up}\t\tdown: #{down}"
  console.log "Time % \t--\tup: #{(up/total*100).toFixed(2)}\t\tdown: #{(down/total*100).toFixed(2)}"