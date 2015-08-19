module.exports = (grunt) ->
  require('./migrations/dublicates')(grunt)
  require('./migrations/statuses')(grunt)
  require('./migrations/regions')(grunt)