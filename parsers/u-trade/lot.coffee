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

  $ = cheerio.load(html)

  rows = $("table[id*='lotNumber']")
  for row in rows
    lot = {}
    for key, val of additional
      lot[key] = val
    t0 = $(row).find('thead tr th').first().text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t1 = $(row).find('span.dashed_underline').first().text().trim().match(/Лот №\d+:(.+)/)?[1].trim()
    t2 = $(row).find("td:contains('Предмет торгов')").first().next().text().trim()
    lot.title = t0 or t1 or t2
    lot.number = $(row).find('span.dashed_underline').first().text().trim().match(/Лот №(\d+):.+/)?[1].trim() or '1'
    lot.information = $(row).find("td:contains('Cведения об имуществе (предприятии) должника, выставляемом на торги, его составе, характеристиках, описание')").first().next().text().trim()
    lot.reviewing_property = $(row).find("td:contains('Порядок ознакомления с имуществом (предприятием) должника')").first().next().text().trim()
    lot.start_price = parseFloat $(row).find("td:contains('Начальная цена продажи имущества')").first().next().text().trim().match(/([\d\s]+\,\d+)/)[0].replace(/\s/g, '')
    step = $(row).find("td:contains('Величина повышения начальной цены')").first().next().text().trim()
    lot.step_percent = parseFloat step.match(/(\d+\,\d+)%/)
    lot.step_sum = parseFloat step.match(/\(([\d\s]+\,\d+)\sруб\.\)/)?[1].replace(/\s/, '')
    lot.status = status $(row).find("td:contains('Статус торгов')").first().next().text().trim()
    deposit_size = $(row).find("td:contains('Размер задатка')").first().next().text().trim()
    if /[\d\s]+\,\d+\s+руб\./.test deposit_size
      lot.deposit_size = parseFloat deposit_size.match(/([\d\s]+\,\d+)/)?[0].replace(/\s/g, '')
    else
      deposit_percent = parseFloat deposit_size.match(/(\d+(\,\d+)?)/)?[1]
      lot.deposit_size = lot.start_price * deposit_percent / 100
    lot.price_reduction_type = $(row).find("td:contains('Порядок снижения цены')").first().next().text().trim()
    lot.current_sum = lot.start_price

    docs = []
    docs_rows = $(row).find("a[href*='/files/download/']")
    for doc in docs_rows
      name = $(doc).text().trim()
      url = etp.href.match(host)[0] + $(doc).attr('href')
      docs.push { name: name, url: url }
    lot.documents = docs
    lots.push lot
  log.info "Parsed #{lots.length} lots"
  return lots