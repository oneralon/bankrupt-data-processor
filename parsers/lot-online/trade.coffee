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

sleep = (time, cb) -> setTimeout cb, time
trim = (text) -> if text? then text.replace(/^\s+/, '').replace(/\s+$/, '') else ''

module.exports = (html, etp, url, headers, cb) ->
  needle.get url, options, (err, resp, body) ->
    needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
      needle.head 'http://bankruptcy.lot-online.ru/e-auction/accessDenied.xhtml', options, ->
        cb err if err?
        $ = cheerio.load body
        vstate = $('input[id="javax.faces.ViewState"]').val().replace(':', '%3A')
        cookies = {JSESSIONID: resp.headers['set-cookie'][0].match(/JSESSIONID=([a-zA-Z0-9.]+);/)[1]}
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
        trade.debtor = {}
        trade.debtor.judgment = $($('div.form-item:contains("Реквизиты судебного акта")').contents().get(3)).text().trim().replace(/\s+/g, ' ')
        trade.debtor.full_name = $($('div.form-item:contains("Наименование")').contents().get(2)).text().trim()
        trade.debtor.short_name = $($('div.form-item:contains("Краткое наименование")').contents().get(2)).text().trim()
        trade.debtor.ogrn = $($('div.form-item:contains("ОГРН")').contents().get(2)).text().trim()
        trade.debtor.inn = $($('div.form-item:contains("ИНН")').contents().get(2)).text().trim()
        trade.debtor.arbitral_name = $($('div.form-item:contains("Наименование суда")').contents().get(2)).text().trim()
        trade.debtor.bankruptcy_number = $($('div.form-item:contains("Полный номер дела о банкротстве")').contents().get(3)).text().trim()

        lot.status = $('span[class*=status-]').text().trim()
        lot.url = trade.url
        lot.number = 1
        lot.title = $('div.product > p.field-description').first().text().trim()
        lot.start_price = parseFloat $('.price.green').text().replace(' руб.', '').replace(/\s/g, '').replace(',', '.')
        lot.step_sum = parseFloat $($('p:contains("Шаг аукциона") > span > span').get(0)).text().replace(/\s/g, '').replace(',', '.')
        lot.step_percent = 100 * lot.step_sum / lot.start_price
        lot.deposit_size = parseFloat $($('p:contains("Сумма задатка") > span ')[1]).text().replace(/\s/g, '').replace(',', '.')
        lot.deposit_payment_date = moment($('p:contains("Окончание приёма задатка") > em').text().trim(), "DD.MM.YYYY HH:mm").toDate()
        lot.intervals = []
        $('.ui-datatable-even, .ui-datatable-odd').each ->
          lot.intervals.push 
            interval_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
            request_start_date: moment($(this).find('td').first().text(), "DD.MM.YYYY").toDate()
            interval_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").toDate()
            request_end_date: moment($(this).find('td').first().next().text(), "DD.MM.YYYY").toDate()
            price_reduction_percent: Math.round(math($(this).find('td').first().next().next().next().text()) / lot.start_price) * 100
            interval_price: math($(this).find('td').first().next().next().next().text())
            deposit_sum: lot.deposit_size

        trade.contract_signing_person = $('legend:contains("Организатор торгов")').parent().find('div > label > strong:contains("Наименование")').parent().parent().text().trim().slice(14, -1).trim()
        trade.lots = [lot]
        # external $, trade, cookies, vstate, (err, saving) ->
        console.log err, trade
        for k, v of trade
          if v isnt  [] and v isnt '' and v isnt null and v isnt undefined
            console.log k
        e()

          # debtor_status = $($('div.form-item:contains("Статус")').contents().get(2)).text().trim()
          # $($('div.form-item:contains("Юридический адрес")').contents().get(2)).text().trim()
          # $($('div.form-item:contains("Номер сообщения ЕФРСБ")').contents().get(2)).text().trim().replace(/\s+/g, ' ')
          # 