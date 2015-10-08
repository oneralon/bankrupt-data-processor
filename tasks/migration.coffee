module.exports = (grunt) ->
  require('./migrations/dublicates')(grunt)
  require('./migrations/statuses')(grunt)
  require('./migrations/regions')(grunt)
  require('./migrations/existing')(grunt)
  require('./migrations/last_message')(grunt)
  require('./migrations/tags')(grunt)