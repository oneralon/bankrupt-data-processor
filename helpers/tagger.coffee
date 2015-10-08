_          = require 'lodash'
mongoose   = require 'mongoose'
config     = require '../config'
logger     = require './logger'
log        = logger  'TAGGER'
keymap     = require './tagger_keymap'

tagFields  = [
  'title'
  'information'
]
require '../models/tag'
сonnection = mongoose.createConnection "mongodb://localhost/#{config.database}"
Tag        = сonnection.model 'Tag'

module.exports = tagger = (lot, cb) ->
  Tag.find {system: true}, (err, keymap) ->
    cb err if err?
    lot.tags = []
    lot.tagInputs = []
    for field in tagFields
      for tag in keymap
        for keyword in tag.keywords
          modifiers = ''
          match = yes
          regex = null
          if typeof keyword is 'object'
            if keyword.ignorecase is no
              modifiers = 'g'
            else
              modifiers = 'ig'
            if keyword.and?
              for pattern in keyword.and
                regex = new RegExp pattern, modifiers
                match = match and regex.test lot[field]
                unless match
                  break
            else
              regex = new RegExp keyword.word, modifiers
              match = regex.test lot[field]
          else
            regex = new RegExp keyword, 'ig'
            match = regex.test lot[field]

          if match
            match = regex?.exec(lot[field]) or regex?.exec(lot[field])
            if match?
              lot.tagInputs.push
                input: lot[field]
                match: match
            if tag.alone
              lot.tags = [tag._id]
              return cb null, lot
            else
              lot.tags.push tag._id
    unless lot.tags.length
      lot.tags.push _.where(keymap, title: 'разное')?[0]?._id
    lot.tags = _.unique lot.tags
    cb null, lot