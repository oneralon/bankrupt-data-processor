moment     = require 'moment'

module.exports.intervalize = (lot, trade) ->
  if lot.intervals.length is 0
    lot.last_event = lot.trade.holding_date
  else
    intervals = lot.intervals.filter (i) -> i.interval_start_date > new Date()
    if intervals.length > 0
      lot.last_event = intervals[0].interval_start_date
    else
      lot.last_event = lot.intervals[lot.intervals.length - 1].interval_start_date
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
          equal = moment(left[k]).format() is moment(v).format()
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