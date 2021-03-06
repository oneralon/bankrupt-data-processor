moment     = require 'moment'

module.exports.intervalize = (lot, trade) ->
  if lot.intervals?
    if lot.intervals.length > 0
      intervals = lot.intervals.filter (i) -> i.interval_start_date > new Date() or i.request_start_date > new Date()
      if intervals.length > 0
        last = intervals[0]
        lot.last_event = last.interval_start_date or last.request_start_date
  unless lot.last_event?
    lot.last_event = trade.holding_date or trade.results_date or trade.requests_end_date or trade.official_publish_date or trade.print_publish_date
  unless lot.last_event?
    lot.present = false
    console.log "No last event present"
  else
    lot.present = new Date() < lot.last_event
  lot

module.exports.diff = (left, right, model) ->
  result = {}
  for k, v of right
    unless v instanceof Object
      switch model.schema.tree[k]
        when String
          equal = String(left[k]) is String(v)
        when Date
          equal = left[k] is v
        when Number
          equal = Number(left[k]) is Number(v)
      unless equal
        if model.schema.tree[k]?
          result[k] = switch model.schema.tree[k]
            when String
              String(v)
            when Date
              moment(v).format()
            when Number
              Number(v)
  result

module.exports.patch = (obj, diff) ->
  for k, v of diff
    if v isnt 'Invalid date'
      obj[k] = v

module.exports.lot = (model, object) ->
  for k, v of object
    model[k] = v

module.exports.trade = (model, object) ->
  model.lots = []
  model.owner     = object.owner
  model.debtor    = object.debtor
  model.etp       = object.etp
  model.documents = object.documents
  for k, v of object
    unless v instanceof Object
      model[k] = v or undefined
