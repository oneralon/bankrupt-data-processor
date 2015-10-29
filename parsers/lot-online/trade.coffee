_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'

iconv     = require 'iconv-lite'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'LOT-ONLINE TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

lotParser = require './lot'

module.exports = (html, etp, url, ismicro, cb) ->
  log.info "Parse trade #{url}"
  $ = cheerio.load html
  trade = {}
  lot = {}
  trade.url = url
  trade.etp = etp
  trade.title = $('div.product > p.field-description').first().text().trim()
  trade.number = $('em.field-lot').text()
  trade.type = $('div.tender').contents().get(0).nodeValue.trim()
  trade.trade_type = type.match(/(аукцион|конкурс|публичное предложение)/i)[0].toLowerCase()
  trade.holding_date = $($('p:contains("Время проведения торгов") > em').first().contents().get(0)).text()
  trade.holding_date += $('p:contains("Время проведения торгов") > em').first().contents().get(1).nodeValue.trim().replace(/c/i, '')
  trade.holding_date = moment(trade.holding_date, "DD.MM.YYYY HH:mm")
  trade.membership_type = if /Открытый/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.price_submission_type = if /открытой/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.submission_procedure = 
  trade.win_procedure = 
  trade.bankrot_date = 
  trade.official_publish_date = 
  trade.requests_start_date = moment $('p:contains("Период приёма заявок") > em > span').first(), "DD.MM.YYYY HH:mm"
  trade.requests_end_date = moment $('p:contains("Период приёма заявок") > em > span').last(), "DD.MM.YYYY HH:mm"
  trade.results_place = 
  trade.additional = 

  trade.debtor = {}
  trade.debtor.judgment = $($('div.form-item:contains("Реквизиты судебного акта")').contents().get(3)).text().trim().replace(/\s+/g, ' ')
  trade.debtor.full_name = $($('div.form-item:contains("Наименование")').contents().get(2)).text().trim()
  trade.debtor.short_name = $($('div.form-item:contains("Краткое наименование")').contents().get(2)).text().trim()
  trade.debtor.ogrn = $($('div.form-item:contains("ОГРН")').contents().get(2)).text().trim()
  trade.debtor.inn = $($('div.form-item:contains("ИНН")').contents().get(2)).text().trim()
  trade.debtor.payment_terms = 
  trade.debtor.contract_procedure = 
  trade.debtor.arbitral_organization = 
  trade.debtor.arbitral_commissioner = 
  trade.debtor.arbitral_name = $($('div.form-item:contains("Наименование суда")').contents().get(2)).text().trim()
  trade.debtor.bankruptcy_number = $($('div.form-item:contains("Полный номер дела о банкротстве")').contents().get(3)).text().trim()

  lot.status = $('span[class*=status-]').text().trim()
  lot.title = $('div.product > p.field-description').first().text().trim()
  lot.start_price = parseFloat $('.price.green').text().replace(' руб.', '').replace(/\s/g, '').replace(',', '.')
  lot.step_sum = parseFloat $($('p:contains("Шаг аукциона") > span > span').get(0)).text().replace(/\s/g, '').replace(',', '.')
  lot.step_percent = 100 * lot.step_sum / lot.start_price
  lot.deposit_size = parseFloat $($('p:contains("Сумма задатка") > span ')[1]).text().replace(/\s/g, '').replace(',', '.')
  lot.deposit_payment_date = moment $('p:contains("Окончание приёма задатка") > em').text().trim(), "DD.MM.YYYY HH:mm"

  debtor_status = $($('div.form-item:contains("Статус")').contents().get(2)).text().trim()
  $($('div.form-item:contains("Юридический адрес")').contents().get(2)).text().trim()
  $($('div.form-item:contains("Номер сообщения ЕФРСБ")').contents().get(2)).text().trim().replace(/\s+/g, ' ')

