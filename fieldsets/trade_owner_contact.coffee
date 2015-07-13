_ = require 'lodash'
moment = require 'moment'

auction_fields =
[
    field: 'name'
    type: String
    title: 'Ф.И.О.'
  ,
    field: 'phone'
    type: String
    title: 'Телефон'
  ,
    field: 'fax'
    type: String
    title: 'Факс'
  ,
]

module.exports = ($, cb) ->
  fieldset = $("fieldset").filter(->
    /контактное лицо организатора торгов/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  result = {}
  fieldset.each () ->
    field = _.where(auction_fields, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          result[field.field] = value.trim()
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
          result[field.field] = if date.isValid() then date.format() else undefined
          break
  cb null, result