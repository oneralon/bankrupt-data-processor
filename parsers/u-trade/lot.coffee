_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'

logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'U-TRADE LOT PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

intervals_fieldsets =
  'm-ets.ru':
    1:
      fields: ['interval_start_date', 'request_start_date']
      type: Date
    2:
      fields: ['interval_end_date', 'request_end_date']
      type: Date
    3:
      fields: ['interval_price']
      type: Number

  'nistp.ru':
    0:
      fields: ['interval_start_date']
      type: Date
    1:
      fields: ['request_start_date']
      type: Date
    2:
      fields: ['request_end_date']
      type: Date
    3:
      fields: ['interval_end_date']
      type: Date
    4:
      fields: ['interval_price']
      type: Number
    5:
      fields: ['deposit_sum']
      type: Number

  'undefined':
    0:
      fields: ['interval_start_date', 'request_start_date']
      type: Date
    1:
      fields: ['interval_end_date', 'request_end_date']
      type: Date
    2:
      fields: ['interval_price']
      type: Number
    3:
      fields: ['deposit_sum']
      type: Number


module.exports = (html, etp, additional) ->
  lots = []
  $ = cheerio.load html,
    xmlMode: true
    decodeEntities: false
    recognizeCDATA: true
    recognizeSelfClosing: true

  $("table[id*=lotNumber], table.data:contains('Лот №'), table.data:contains('Сведения о предмете торгов'), table.data:contains('Информация о предмете торгов'), table:contains('Сведения по лоту №')").each ->
    lot = {}
    for key, val of additional
      lot[key] = val
    t0 = $(@).find('thead tr th')?.text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t1 = $(@).find('span.dashed_underline')?.text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t2 = $(@).find("td:contains('Предмет торгов')")?.next().text().trim()
    t3 = $(@).find("span:contains('Лот №')")?.text().replace(/Лот №\d+:/i, '').trim()
    t4 = $(@).find('td:contains("Краткие сведения об имуществе (предприятии) должника (наименование лота) ")')?.next().text().trim()
    lot.title = t0 or t1 or t2 or t3 or t4
    lot.number = $(@).find('span.dashed_underline, th:contains("лоту №")')?.text().trim().match(/Лоту? №(\d+)/i)?[1].trim() or '1'
    lot.information = $(@).find("td:contains('Cведения об имуществе (предприятии) должника, выставляемом на торги, его составе, характеристиках, описание')")?.next().text().trim()
    lot.reviewing_property = $(@).find("td:contains('Порядок ознакомления с имуществом (предприятием) должника')")?.next().text().trim()
    lot.start_price = parseFloat $(@).find("td:contains('Начальная цена продажи имущества')")?.next().text().trim().match(/([\d\s]+\,\d+)/)?[0]?.replace(/\s/g, '')
    step = $(@).find("td:contains('Величина повышения начальной цены')")?.next().text().trim()
    lot.step_percent = parseFloat step.match(/(\d+\,\d+)%/)
    lot.step_sum = parseFloat step.match(/\(([\d\s]+\,\d+)\sруб\.\)/)?[1].replace(/\s/, '')
    lot.status = status $(@).find("td:contains('Статус торгов')")?.next().text().trim()
    deposit_size = $(@).find("td:contains('Размер задатка')")?.next().text().trim()
    if /[\d\s]+\,\d+\s+руб\./.test deposit_size
      lot.deposit_size = parseFloat deposit_size.match(/([\d\s]+\,\d+)/)?[0]?.replace(/\s/g, '')
    else
      deposit_percent = parseFloat deposit_size.match(/(\d+(\,\d+)?)/)?[1]
      lot.deposit_size = lot.start_price * deposit_percent / 100
    lot.price_reduction_type = $(@).find("td:contains('Порядок снижения цены')")?.next().text().trim()
    lot.current_sum = lot.start_price

    interval_rows = $(@).find('div:contains("Интервалы снижения цены"), td:contains("График снижения цены")').next().find('tr')
    interval_rows = interval_rows.filter -> /\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}/.test $(@).find('td').first().next().text().trim()
    for k, v of intervals_fieldsets
      if new RegExp(k.replace('.', '\.').replace('-', '\-')).test etp.href then fieldsets = v
    fieldsets = fieldsets or intervals_fieldsets['undefined']
    interval_rows.each ->
      lot.intervals = lot.intervals or []
      interval = {}
      $(@).find('td').each (i) ->
        fieldset = fieldsets[i]
        if fieldset?
          switch fieldset.type
            when Date then value = moment $(@).text().trim(), "DD.MM.YYYY"
            when Number then value = parseFloat $(@).text().trim().match(/([\d\s]+\,\d+)/)?.pop().replace(/\s/g, '')
          for field in fieldset.fields
            interval[field] = value
      lot.intervals.push interval

    docs = []
    docs_rows = $(@).find("a[href*='/files/download/']")
    $(@).find("a[href*='/files/download/']").each ->
      name = $(@).text().trim()
      url = etp.href.match(host)?[0] + $(@).attr('href')
      docs.push { name: name, url: url }
    lot.documents = docs
    console.log lot
    lots.push lot
  log.info "Parsed #{lots.length} lots"
  return lots
