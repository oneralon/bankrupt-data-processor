load = require 'load-grunt-config'

module.exports = (grunt)->
  load grunt, jitGrunt:
    staticMappings:
      collect: 'tasks/collect.coffee'
      consumers: 'tasks/consumers.coffee'
      update: 'tasks/update.coffee'