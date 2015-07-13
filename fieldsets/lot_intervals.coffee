_ = require 'lodash'
moment = require 'moment'

auction_fields =
[
    field: 'interval_start_date'
    type: Date
    title: 'Дата начала интервала'
  ,
    field: 'request_start_date'
    type: Date
    title: 'Дата начала приема заявок на интервале'
  ,
    field: 'request_end_date'
    type: Date
    title: 'Дата окончания приема заявок на интервале'
  ,
    field: 'interval_end_date'
    type: Date
    title: 'Дата окончания интервала'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение цены предыдущего интервала на процент от начальной цены, проценты'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение от предыдущей цены, проценты'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение от предыдущей цены, рубли'
  ,
    field: 'deposit_sum'
    type: Number
    title: 'Задаток на интервале, руб.'
  ,
    field: 'interval_price'
    type: Number
    title: 'Цена на интервале, руб.'
  ,
    field: 'comment'
    type: String
    title: 'Комментарий'
]

module.exports = ($, cb) ->
  fieldset = $('fieldset').filter(->
    $(@).find('legend').text().trim() is 'Интервалы снижения цены'
  ).find('tr.gridRow')
  fieldNames = $('fieldset').filter(->
    $(@).find('legend').text().trim() is 'Интервалы снижения цены'
  ).find('tr.gridHeader td')
  result = []
  fieldset.each ->
    interval = {}
    fields = $(@).find('td')
    values = fields.map -> $(@).text().trim()
    for i in [0..fieldNames.length - 1]
      field = _.where(auction_fields, title: fieldNames.eq(i).text().replace(/(:|\(\*\))/g, '').trim())?[0]
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
    result.push interval
  cb null, result