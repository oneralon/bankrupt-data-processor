_         = require 'lodash'
mongoose  = require 'mongoose'

config    = require "../config"

keymap  = require './tagger_keymap'

require '../models/tag'

prodConnection  = mongoose.createConnection "mongodb://localhost/#{config.db}"

tagFields = [
  'title'
  'information'
]

Tag       = prodConnection.model 'Tag'


module.exports = tagger = (lot, cb) ->
  prodConnection.collection('tags').find system: yes, (err, cursor) ->
    console.error err if err?
    cursor.toArray (err, keymap) ->
      console.error err if err?
      lot.tags = []
      lot.tagInputs = []
      try
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
      catch e
        console.error e
      lot.tags = _.unique lot.tags
      # prodConnection.close()
      cb null, lot