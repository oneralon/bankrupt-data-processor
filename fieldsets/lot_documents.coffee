_ = require 'lodash'
moment = require 'moment'

module.exports = ($, cb) ->
  fieldset = $('fieldset').filter( -> $(@).find('legend').text().trim() is 'Документы').find('tr.gridRow td a:not([href="#"])')
  result = []
  fieldset.each ->
    result.push {
      url: process.env.moduleUrl + $(@).attr('href')
      name: $(@).text()
    }
  cb null, result