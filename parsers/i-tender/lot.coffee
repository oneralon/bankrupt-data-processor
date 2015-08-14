_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'

logger    = require '../../helpers/logger'
log       = logger  'I-TENDER LOT PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

fieldsets = require './lot-fieldset'

module.exports = (html, etp) ->
  $ = cheerio.load(html)
  lot = {}
  fieldset = $("fieldset").filter( ->
    /информация о лоте/i.test $(@).find("legend").text().trim()
  ).find("td.tdTitle").add $('fieldset').filter( ->
    $(@).find('legend').text().trim() is 'Обеспечение задатка'
  ).find('td.tdTitle')
  fieldset.each ->
    field = _.where(fieldsets.info, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          lot[field.field] = value.trim()
          break
        when Number
          lot[field.field] = Number(value.trim().replace(/\s/g, '').replace(/,/g, '.').replace(/%/g, '').trim())
          break
        when Date
          switch value.length
            when 16
              format = "DD.MM.YYYY HH:mm"
              break
            when 10
              format = "DD.MM.YYYY"
              break
          date = moment(value, format)
          lot[field.field] = if date.isValid() then date.format() else undefined
          break
  fieldset = $('fieldset').filter( ->
    $(@).find('legend').text().trim() is 'Интервалы снижения цены'
  ).find('tr.gridRow')
  fieldNames = $('fieldset').filter( ->
    $(@).find('legend').text().trim() is 'Интервалы снижения цены'
  ).find('tr.gridHeader td')
  lot.intervals = []
  fieldset.each ->
    interval = {}
    fields = $(@).find('td')
    values = fields.map -> $(@).text().trim()
    for i in [0..fieldNames.length - 1]
      field = _.where(fieldsets.interval, title: $(fieldNames[i]).text().replace(/(:|\(\*\))/g, '').trim())?[0]
      if field?
        value = values[i]
        switch field.type
          when String
            interval[field.field] = value.trim()
            break
          when Number
            interval[field.field] = Number(value.trim().replace(/\s/g, '').replace(/,/g, '.').replace(/%/g, '').trim())
            break
          when Date
            switch value.length
              when 16
                format = "DD.MM.YYYY HH:mm"
                break
              when 10
                format = "DD.MM.YYYY"
                break
            date = moment(value, format)
            interval[field.field] = if date.isValid() then date.format() else undefined
            break
    lot.intervals.push interval
  fieldset = $('fieldset').filter( -> $(@).find('legend').text().trim() is 'Документы').find('tr.gridRow td a:not([href="#"])')
  lot.documents = []
  fieldset.each ->
    lot.documents.push {
      url: etp.href.match(host)[0] + $(@).attr('href')
      name: $(@).text()
    }
  return lot