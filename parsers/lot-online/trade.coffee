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
    parseFloat(text.replace(/\s/g, '').replace(',','.'))
  else null

options =
  proxy: 'http://127.0.0.1:18118'
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true
  open_timeout: 120000
  headers: {}
  cookies: {}

external = require './external'

trim = (text) -> if text? then text.replace(/^\s+/, '').replace(/\s+$/, '') else ''

module.exports = (html, etp, url, headers, cb) ->
  needle.get url, options, (err, resp, body) ->
    return cb err if err?
    if not resp.headers['set-cookie']?
      cookies = {JSESSIONID: resp.connection._httpMessage._header.match(/JSESSIONID=([a-zA-Z0-9.]+)/)[1]}
    else cookies = {JSESSIONID: resp.headers['set-cookie'][0].match(/JSESSIONID=([a-zA-Z0-9.]+);/)[1]}
    options.cookies = cookies
    options.headers['Referer'] = url
    $ = cheerio.load body
    vstate = body.match(/value\=\"(\-?\d+\:\-?\d+)\"/)?[1].replace(':', '%3A')
    needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
      cb err if err?
      needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
        cb err if err?
        log.info "Parse trade #{url}"
        $ = cheerio.load body
        trade = {}
        lot = {}
        trade.url = url
        trade.etp = etp
        trade.title = $('div.product > p.field-description').first().text().trim()
        trade.number = $('em.field-lot').text()
        trade.type = $('div.tender').clone().children().remove().end().text().trim()
        trade.trade_type = trade.type.match(/(аукцион|конкурс|публичного предложения)/i)[0].toLowerCase().replace('публичного предложения', 'публичное предложение')
        trade.membership_type = if /Открытый/.test(trade.type) then 'Открытая' else 'Закрытая'
        trade.price_submission_type = if /открытой/.test(trade.type) then 'Открытая' else 'Закрытая'
        trade.requests_start_date = moment($('p:contains("Период приёма заявок") > em > span').first(), "DD.MM.YYYY HH:mm").toDate()
        trade.requests_end_date = moment($('p:contains("Период приёма заявок") > em > span').last(), "DD.MM.YYYY HH:mm").toDate()
        holding_date = $('p:contains("Время проведения торгов")').find('em > span').first().text()
        if holding_date isnt ''
          trade.holding_date = moment(holding_date, "DD.MM.YYYY HH:mm").toDate()
        else trade.holding_date = trade.requests_end_date
        trade.additional = 'Для участия в торгах необходима электронная подпись'
        trade.contract_signing_person = null
        trade.debtor = {}
        trade.debtor.debtor_type = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("Статус")').clone().children().remove().end().text().trim()
        trade.debtor.judgment = $('fieldset > legend:contains("Должник")').parent().find('div.form-item:contains("Реквизиты судебного акта")').clone().children().remove().end().text().trim()
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
          interval_price = math($(this).find('td').first().next().next().next().text())
          lot.intervals.push
            interval_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
            request_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
            interval_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").subtract(1, 'seconds').toDate()
            request_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").subtract(1, 'seconds').toDate()
            price_reduction_percent: interval_price / lot.start_price * 100
            interval_price: interval_price
            deposit_sum: lot.deposit_size
        if lot.intervals.length > 0
          active = lot.intervals.filter (i) -> i.interval_end_date > new Date()
          interval = active[0] or lot.intervals[lot.intervals.length - 1]
          lot.current_sum = interval.interval_price
        else lot.current_sum = lot.start_price
        lot.discount = lot.start_price - lot.current_sum
        lot.discount_percent = lot.discount / lot.start_price * 100
        trade.lots = [lot]
        external $, trade, cookies, vstate, (err, extended) ->
          if err? then cb(err)
          else if extended? then cb(null, extended) else cb('Error on returning')