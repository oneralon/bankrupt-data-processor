_ = require 'lodash'
moment = require 'moment'
tagger = require './../helpers/tagger'

auction_fields =
[
    field: 'number'
    type: Number
    title: 'Номер'
  ,
    field: 'title'
    type: String
    title: 'Наименование'
  ,
    field: 'status'
    type: String
    title: 'Статус'
  ,
    field: 'procedure'
    type: String
    title: 'Порядок оформления участия в торгах, перечень представляемых участниками торгов документов и требования к их оформлению'
  ,
    field: 'category'
    type: String
    title: 'Категория лота'
  ,
    field: 'currency'
    type: String
    title: 'Валюта цены по ОКВ'
  ,
    field: 'start_price'
    type: Number
    title: 'Начальная цена, руб.'
  ,
    field: 'information'
    type: String
    title: 'Сведения об имуществе должника, его составе, характеристиках, описание, порядок ознакомления'
  ,
    ###
      * Для аукциона
    ###
    field: 'step_percent'
    type: Number
    title: 'Шаг, % от начальной цены'
  ,
    field: 'step_sum'
    type: Number
    title: 'Шаг, руб.'
  ,
    ###
      * Для публичного предложения
    ###
    field: 'price_reduction_type'
    type: String
    title: 'Тип снижения цены публичного предложения'
  ,
    field: 'current_sum'
    type: Number
    title: 'Текущая цена, руб.'
  ,
    field: 'calc_method'
    type: String
    title: 'Способ расчета обеспечения'
  ,
    field: 'deposit_size'
    type: Number
    title: 'Размер задатка, руб.'
  ,
    field: 'deposit_payment_date'
    type: String
    title: 'Дата внесения задатка'
  ,
    field: 'deposit_return_date'
    type: String
    title: 'Дата возврата задатка'
  ,
    field: 'deposit_procedure'
    type: String
    title: 'Порядок внесения и возврата задатка'
  ,
    field: 'bank_name'
    type: String
    title: 'Название банка'
  ,
    field: 'payment_account'
    type: String
    title: 'Расчетный счет'
  ,
    field: 'correspondent_account'
    type: String
    title: 'Кор. счет'
  ,
    field: 'bik'
    type: String
    title: 'БИК'
]

module.exports = ($, cb) ->
  fieldset = $("fieldset").filter(->
    /информация о лоте/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  .add $('fieldset').filter(->
    $(@).find('legend').text().trim() is 'Обеспечение задатка'
  ).find('td.tdTitle')
  result = {}
  fieldset.each () ->
    field = _.where(auction_fields, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          result[field.field] = value.trim()
          break
        when Number
          result[field.field] = Number(value.trim().replace(/\s/g, '').replace(/,/g, '.').replace(/%/g, '').trim())
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
  tagger result, cb