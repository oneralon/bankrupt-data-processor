_ = require 'lodash'
moment = require 'moment'
log             = require('./../helpers/logger')()

auction_fields =
[
    field: 'membership_type'
    type: String
    title: 'Форма торга по составу участников'
    params:
      lower_case: yes
  ,
    field: 'price_submission_type'
    type: String
    title: 'Форма представления предложений о цене'
    params:
      lower_case: yes
  ,
    field: 'title'
    type: String
    title: 'Наименование'
  ,
    field: 'additional'
    type: String
    title: 'Дополнительные сведения'
  ,
    field: 'win_procedure'
    type: String
    title: 'Порядок и критерии определения победителя торгов'
  ,
    field: 'submission_procedure'
    type: String
    title: 'Порядок представления заявок на участие в торгах'
  ,
    field: 'holding_date'
    type: Date
    title: 'Дата проведения'
  ,
    ###
      * Для аукциона
    ###
    field: 'requests_start_date'
    type: Date
    title: 'Дата начала представления заявок на участие'
  ,
    field: 'requests_end_date'
    type: Date
    title: 'Дата окончания представления заявок на участие'
  ,
    ###
      * Для торгов
    ###
    field: 'intervals_start_date'
    type: Date
    title: 'Дата начала первого интервала'
  ,
    field: 'interval_end_date'
    type: Date
    title: 'Дата окончания последнего интервала'
  ,
    field: 'official_publish_date'
    type: Date
    title: 'Дата публикации сообщения о проведении открытых торгов в официальном издании'
  ,
    field: 'print_publish_date'
    type: Date
    title: 'Дата публикации в печатном органе по месту нахождения должника'
  ,
    field: 'bankrot_date'
    type: Date
    title: 'Дата размещения сообщения в Едином федеральном реестре сведений о банкротстве'
  ,
    field: 'results_place'
    type: String
    title: 'Место'
  ,
    field: 'results_date'
    type: Date
    title: 'Дата'
  ,
    field: 'contract_signing_person'
    type: String
    title: 'Лицо, подписывающее договор'
]

module.exports = ($, cb) ->
  fieldset = $("fieldset").filter(->
    /информация о(б аук| пуб| кон)/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  .add $("fieldset").filter(->
    /подведение результатов/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  .add $("fieldset").filter(->
    /подписывающее договор/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  result = {}
  fieldset.each () ->
    field = _.where(auction_fields, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          result[field.field] = value.trim()
          if field.params?.lower_case
            result[field.field] = value?.trim().toLowerCase()
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