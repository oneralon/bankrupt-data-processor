_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'

logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'U-TRADE LOT PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

module.exports = (html, etp, additional) ->
  lots = []

  $ = cheerio.load html,
    xmlMode: true
    decodeEntities: false
    recognizeCDATA: true
    recognizeSelfClosing: true

  $("table[id*=lotNumber], table.data:contains('Лот №'), table.data:contains('Сведения о предмете торгов')").each ->
    lot = {}
    for key, val of additional
      lot[key] = val
    t0 = $(@).find('thead tr th')?.text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t1 = $(@).find('span.dashed_underline')?.text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t2 = $(@).find("td:contains('Предмет торгов')")?.next().text().trim()
    t3 = $(@).find("span:contains('Лот №')")?.text().replace(/Лот №\d+:/i, '').trim()
    lot.title = t0 or t1 or t2 or t3
    lot.number = $(@).find('span.dashed_underline')?.text().trim().match(/Лот №(\d+):.+/)?[1].trim() or '1'
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

    docs = []
    docs_rows = $(@).find("a[href*='/files/download/']")
    $(@).find("a[href*='/files/download/']").each ->
      name = $(@).text().trim()
      url = etp.href.match(host)?[0] + $(@).attr('href')
      docs.push { name: name, url: url }
    lot.documents = docs
    lots.push lot
  log.info "Parsed #{lots.length} lots"
  return lots