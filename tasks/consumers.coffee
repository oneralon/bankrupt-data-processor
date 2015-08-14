spawn = require('child_process').spawn

module.exports = (grunt) ->
  grunt.registerTask 'consumers:start', ->
    done = @async()
    spawn 'nodemon', ['consumers/lists-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'nodemon', ['consumers/trades-html.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'nodemon', ['consumers/trades-url.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    spawn 'nodemon', ['consumers/trades-json.coffee'], { detached: true, stdio: ['ignore', 'ignore', 'ignore']}
    done()