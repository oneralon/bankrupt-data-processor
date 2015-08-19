spawn = require('child_process').spawn

module.exports = (grunt) ->
  grunt.registerTask 'consumers:start', ->
    done = @async()
    spawn 'coffee', ['consumers/lists-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'coffee', ['consumers/trades-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'coffee', ['consumers/trades-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'coffee', ['consumers/trades-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    done()