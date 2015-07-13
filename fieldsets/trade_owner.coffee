_ = require 'lodash'
moment = require 'moment'

auction_fields =
[
    field: 'short_name'
    type: String
    title: 'Сокращенное наименование'
  ,
    field: 'full_name'
    type: String
    title: 'Полное наименование'
  ,
    field: 'internet_address'
    type: String
    title: 'Адрес сайта'
  ,
    field: 'inn'
    type: String
    title: 'ИНН'
  ,
    field: 'kpp'
    type: String
    title: 'КПП'
  ,
    field: 'ogrn'
    type: String
    title: 'ОГРН'
  ,
    field: 'ogrnip'
    type: String
    title: 'ОГРНИП'
]




module.exports = ($, cb) ->
  fieldset = $("fieldset").filter(->
    /организатор торгов/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  result = {}
  fieldset.each () ->
    field = _.where(auction_fields, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text().trim()
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