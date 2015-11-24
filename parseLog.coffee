fs    = require 'fs'
parse = (line) ->
  res = line.match(/(\d+\.\d+\.\d+\.\d+)\s\-\s\[([\d\/\s\:\+\w]+)\]\s(\d+\.\d+\.\d+\.\d+)\s\"(.*?)\"\s(\d+)/)
  return {
    status: parseInt res[5]
    time_local: new Date res[2]
  }



fs.readFile 'nginx.log', (err, logData) ->
  if err? then throw err
  text = logData.toString()
  results = {}
  lines = text.split('\n')
  start_time = parse(lines[0]).time_local
  end_time = parse(lines[lines.length - 1]).time_local
  console.log "Time: #{start_time} -- #{end_time}"
  result = {}
  current_stat = parse(lines[0]).status
  interval_start = parse(lines[0]).time_local
  lines.forEach (line) ->
    res = parse(line)
    if res.status isnt current_stat
      result[current_stat.toString()] = result[current_stat.toString()] or 0
      result[current_stat.toString()] += res.time_local - interval_start
  console.log result