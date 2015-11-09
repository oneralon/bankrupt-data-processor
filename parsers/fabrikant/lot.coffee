_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'

logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'FABRIKANT LOT PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

math = (text) ->
  if text isnt ''
    parseFloat(text.match(/(.+)руб/)[1].replace(/\s/, '').replace(',','.'))
  else null

module.exports = (html, etp, url, cb) ->
  lot = {}
  $ = cheerio.load html

  lot.number = 1
  lot.title = $('td.fname:contains("реализуемого")').next().find('b').text().trim()
  lot.procedure = "Документы, прилагаемые к заявке: " + $('td.fname:contains("Документы, прилагаемые к заявке:")').next().text()
  lot.category = $('td.fname:contains("Категория имущества")').next().text()
  lot.currency = 'Российская Федерация'
  lot.start_price = math $('td.fname:contains("Начальная цена предмета договора")').next().text()
  lot.information = $('td.fname:contains("реализуемого")').next().html().match(/^(.+)<br>/)[1] + ': '
  lot.information += $('td.fname:contains("реализуемого")').next().find('b').text().trim() + ' '
  lot.information += 'Месторасположение предмета торгов: ' + $('td.fname:contains("Месторасположение предмета торгов:")').next().text()
  lot.step_sum = math $('td.fname:contains("Шаг аукциона")').next().text()
  lot.step_percent = Math.round(lot.step_sum / lot.start_price) * 100
  lot.current_sum = math $('td.fname:contains("Текущая цена")').next().text()
  lot.deposit_procedure = $('td.fname:contains("Обеспечение заявок и исполнения договора")').next().text()
  lot.payment_account = $('td.fname:contains("Условия оплаты")').next().text()

  cb null, lot