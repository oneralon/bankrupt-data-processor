_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'
needle    = require 'needle'

iconv     = require 'iconv-lite'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'LOT-ONLINE TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

math = (text) ->
  if text isnt ''
    parseFloat(text.replace(/\s/, '').replace(',','.'))
  else null

options =
  proxy: 'http://127.0.0.1:18118'
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true
  open_timeout: 120000

external = require './external'

trim = (text) -> if text? then text.replace(/^\s+/, '').replace(/\s+$/, '') else ''

module.exports = (html, etp, url, headers, cb) ->
  # console.log url
  # needle.get url, options, (err, resp, body) ->
  #   needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
  #     needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
  #       cb err if err?
  $ = cheerio.load html
  vstate = $('input[id="javax.faces.ViewState"]').val().replace(':', '%3A')
  # cookies = {JSESSIONID: resp.headers['set-cookie'][0].match(/JSESSIONID=([a-zA-Z0-9.]+);/)[1]}
  log.info "Parse trade #{url}"
  $ = cheerio.load html
  trade = {}
  lot = {}
  trade.url = url
  trade.etp = etp
  trade.title = $('div.product > p.field-description').first().text().trim()
  trade.number = $('em.field-lot').text()
  trade.type = trim($('div.tender')['0'].children[0].data).toString()
  trade.trade_type = trade.type.match(/(аукцион|конкурс|публичное предложение)/i)[0].toLowerCase()
  trade.membership_type = if /Открытый/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.price_submission_type = if /открытой/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.requests_start_date = moment($('p:contains("Период приёма заявок") > em > span').first(), "DD.MM.YYYY HH:mm").toDate()
  trade.requests_end_date = moment($('p:contains("Период приёма заявок") > em > span').last(), "DD.MM.YYYY HH:mm").toDate()
  trade.additional = 'Для участия в торгах необходима электронная подпись'
  trade.contract_signing_person = null
  trade.debtor = {}
  trade.debtor.debtor_type = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("Статус")').clone().children().remove().end().text().trim()
  trade.debtor.judgment = $('fieldset > legend:contains("Реквизиты судебного акта")').parent().find('div.form-item:contains("Статус")').clone().children().remove().end().text().trim()
  trade.debtor.full_name = $('fieldset > legend:contains("Наименование")').parent().find('div.form-item:contains("Статус")').clone().children().remove().end().text().trim()
  trade.debtor.short_name = $('fieldset > legend:contains("Краткое наименование")').parent().find('div.form-item:contains("Статус")').clone().children().remove().end().text().trim()
  trade.debtor.ogrn = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("ОГРН")').clone().children().remove().end().text().trim()
  trade.debtor.inn = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("ИНН")').clone().children().remove().end().text().trim()
  trade.debtor.arbitral_name = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("Наименование суда")').clone().children().remove().end().text().trim()
  trade.debtor.bankruptcy_number = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("Полный номер дела о банкротстве")').clone().children().remove().end().text().trim()
  trade.owner = {}
  trade.owner.full_name = $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Наименование")').parent().parent().text().trim().slice(14, 999).trim()
  trade.owner.short_name = $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Наименование")').parent().parent().text().trim().slice(14, 999).trim()
  trade.owner.inn = null
  trade.owner.internet_address = null
  trade.owner.contact =
    name: null
    fax: null
    phone: $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Телефоны")').parent().parent().text().trim().slice(10, 999).trim()
    address: $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Юридический адрес")').parent().parent().text().trim().slice(19, 999).trim()
    email: $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Электронная почта")').parent().parent().text().trim().slice(19, 999).trim()



  lot.status = $('span[class*=status-]').text().trim()
  lot.url = trade.url
  lot.number = 1
  lot.currency = if $('span.rub').length > 0 then 'Российская Федерация' else null
  if trade.trade_type is 'публичное предложение'
    lot.price_reduction_type = 'Цена на интервале задается как цена на предыдущем интервале минус процент снижения от начальной цены'
  else lot.price_reduction_type = null
  lot.title = $('table.LotHeader h1').first().clone().children().remove().end().text().trim().replace(/,$/, '')
  lot.information = $('div.product > p.field-description').first().text().trim()
  lot.start_price = parseFloat $('.price.green').text().replace(' руб.', '').replace(/\s/g, '').replace(',', '.')
  lot.step_sum = parseFloat $($('p:contains("Шаг аукциона") > span > span').get(0)).text().replace(/\s/g, '').replace(',', '.')
  lot.step_percent = 100 * lot.step_sum / lot.start_price
  lot.deposit_size = parseFloat $($('p:contains("Сумма задатка") > span ')[1]).text().replace(/\s/g, '').replace(',', '.')
  lot.deposit_payment_date = moment($('p:contains("Окончание приёма задатка") > em').text().trim(), "DD.MM.YYYY HH:mm").toDate()
  lot.deposit_return_date = lot.bik = lot.correspondent_account = lot.bank_name = null
  lot.calc_method = null

  lot.intervals = []
  $('.ui-datatable-even, .ui-datatable-odd').each ->
    lot.intervals.push
      interval_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
      request_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
      interval_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").subtract(1, 'seconds').toDate()
      request_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").subtract(1, 'seconds').toDate()
      price_reduction_percent: Math.round(math($(this).find('td').first().next().next().next().text()) / lot.start_price) * 100
      interval_price: math($(this).find('td').first().next().next().next().text())
      deposit_sum: lot.deposit_size


  trade.lots = [lot]
  # external $, trade, cookies, vstate, (err, saving) ->
  console.log trade
  for k, v of trade
    if v isnt  [] and v isnt '' and v isnt null and v isnt undefined
      console.log k
  e()

          # debtor_status = $($('div.form-item:contains("Статус")').contents().get(2)).text().trim()
          # $($('div.form-item:contains("Юридический адрес")').contents().get(2)).text().trim()
          # $($('div.form-item:contains("Номер сообщения ЕФРСБ")').contents().get(2)).text().trim().replace(/\s+/g, ' ')
          #