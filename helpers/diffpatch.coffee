moment    = require 'moment'
_         = require 'lodash'

module.exports = diffpatch =
  diff: (left, right, model) ->
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

  patch: (obj, diff) ->
    for k, v of diff
      obj[k] = v