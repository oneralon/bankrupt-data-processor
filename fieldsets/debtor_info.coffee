_ = require 'lodash'
moment = require 'moment'

auction_fields =
[
    field: 'debtor_type'
    type: String
    title: 'Тип должника'
  ,
    field: 'inn'
    type: String
    title: 'ИНН'
  ,
    field: 'short_name'
    type: String
    title: 'Сокращенное наименование'
  ,
    field: 'full_name'
    type: String
    title: 'Полное наименование'
  ,
    field: 'ogrn'
    type: String
    title: 'ОГРН'
  ,
    field: 'judgment'
    type: String
    title: 'Основание для проведения торгов (реквизиты судебного акта арбитражного суда)'
  ,
    field: 'reviewing_property'
    type: String
    title: 'Порядок ознакомления с имуществом'
  ,
    field: 'region'
    type: String
    title: 'Регион'
  ,
    field: 'arbitral_name'
    type: String
    title: 'Наименование арбитражного суда'
  ,
    field: 'bankruptcy_number'
    type: String
    title: 'Номер дела о банкротстве'
  ,
    field: 'arbitral_commissioner'
    type: String
    title: 'Арбитражный управляющий'
  ,
    field: 'arbitral_organization'
    type: String
    title: 'Наименование организации арбитражных управляющих'
  ,
    field: 'contract_procedure'
    type: String
    title: 'Порядок и срок заключения договора купли-продажи'
  ,
    field: 'payment_terms'
    type: String
    title: 'Сроки платежей, реквизиты счетов'
]




module.exports = ($, cb) ->
  fieldset = $("fieldset").filter(->
    /информация о должнике/i.test $(this).find("legend").text().trim()
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