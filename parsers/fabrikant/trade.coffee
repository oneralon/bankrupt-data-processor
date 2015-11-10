_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'
needle    = require 'needle'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
regionize = require '../../helpers/regionize'
status    = require '../../helpers/status'
log       = logger  'FABRIKANT TRADE PARSER'
config    = require '../../config'
host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

options =
  # proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true
  open_timeout: 120000

math = (text) ->
  if text isnt ''
    parseFloat(text.match(/(.+)руб/)?[1].replace(/\s/g, '').replace(',','.'))
  else null

module.exports = (html, etp, url, ismicro, cb) ->
  log.info "Parse trade #{url}"
  trade = {}
  lot   = {}
  trade.url = lot.url = url
  trade.etp = etp
  $ = cheerio.load html
  Sync =>
    try
      trade.title = $('td.fname:contains("реализуемого")').next().find('b').text().trim()
      trade.type = $('td.fname:contains("Форма аукциона")').next().text()
      trade.membership_type = if /Открытый/.test(trade.type) then 'Открытая' else 'Закрытая'
      trade.price_submission_type = if /открытой/.test(trade.type) then 'Открытая' else 'Закрытая'
      trade.win_procedure = $('td.fname:contains("Порядок и критерии выявления победителя")').next().text().trim()
      trade.submission_procedure = $('td.fname:contains("Порядок подачи заявок на участие")').next().text().trim()
      trade.official_publish_date = moment($('td.fname:contains("Дата публикации в печатных СМИ")').next().text().match(/от ([\d\.]+)/)?[1], "DD.MM.YYYY").toDate()
      trade.print_publish_date =  moment($('td.fname:contains("Дата публикации в печатных СМИ по месту нахождения должника")').next().text().match(/от ([\d\.]+)/)?[1], "DD.MM.YYYY").toDate()
      trade.holding_date = moment($('td.fname:contains("Дата и время подведения итогов")').next().text().trim(), "DD.MM.YYYY HH:mm").toDate()
      trade.results_place = $('td.fname:contains("Место проведения")').next().text().trim()
      trade.additional = $('td.fname:contains("Условия передачи имущества")').next().text().trim()
      trade.debtor = {}
      trade.debtor.full_name = $('td.fname:contains("Должник")').next().text().match(/(.+)\(/)?[1]
      trade.debtor.short_name = null
      trade.debtor.inn = $('td.fname:contains("Должник")').next().text().match(/ИНН:\s(\d+)/)?[1]
      trade.debtor.ogrn = $('td.fname:contains("Должник")').next().text().match(/ОГРН:\s(\d+)/)?[1]
      trade.debtor.arbitral_commissioner = $('td.fname:contains("Арбитражный управляющий")').next().text().match(/(.+)\(/)?[1].trim()
      trade.debtor.arbitral_name = $('td.fname:contains("Наименование арбитражного суда")').next().text()
      trade.debtor.bankruptcy_number = $('td.fname:contains("Номер дела о банкротстве")').next().text()
      trade.debtor.reviewing_property = $('td.fname:contains("Порядок ознакомления с имуществом")').next().text()
      trade.debtor.arbitral_organization = $('td.fname:contains("членом которой является арбитражный управляющий")').next().text()
      trade.debtor.contract_procedure = $('td.fname:contains("Порядок и сроки заключения договора ")').next().text()
      trade.debtor.payment_terms = lot.payment_account = $('td.fname:contains("Условия оплаты")').next().text()
      trade.debtor.judgment = null
      trade.requests_start_date = moment($('td.fname:contains("Дата публикации в МТС \"Фабрикант.ру\"")').next().text().trim(), "DD.MM.YYYY HH:mm").toDate()
      trade.requests_end_date = moment($('td.fname:contains("Дата окончания приема аукционных заявок в аукционе")').next().find('b').text().trim(), "DD.MM.YYYY HH:mm").toDate()
      trade.holding_date = moment($('td.fname:contains("Дата подведения результатов торгов")').next().text().trim() or $('td.fname:contains("Дата начала аукциона")').next().text().trim(), "DD.MM.YYYY HH:mm").toDate()
      trade.debtor.debtor_type = 'Не определен'
      if /(ООО|АО|ЗАО|ПАО|ОАО|ГУП|ФГУП|МУП)/i.test trade.debtor.full_name then trade.debtor.debtor_type = 'Юридическое лицо'
      if /(ПБОЮЛ|ИП)/i.test trade.debtor.full_name then trade.debtor.debtor_type = 'Индивидуальный предприниматель'
      trade.bankrot_date = trade.requests_start_date
      trade.contract_signing_person = $('td.fname:contains("Организатор процедуры")').next().find('a').text()
      ownerUrl = 'https://www.fabrikant.ru' + $('td.fname:contains("Организатор процедуры")').next().find('a').attr('href')
      resp = needle.get.sync null, ownerUrl, options
      ownerPage = cheerio.load resp[1]
      trade.owner = {}
      trade.owner.short_name = ownerPage('td.fname:contains("Краткое наименование организации")').next().text()
      trade.owner.full_name = ownerPage('td.fname:contains("Полное наименование организации")').next().text()
      trade.owner.internet_address = ownerPage('td.fname:contains("Адрес корпоративного web-сайта")').next().text()
      trade.owner.contact =
        name: $('td.fname:contains("Организатор процедуры")').next().find('a').text()
        address: ownerPage('td.fname:contains("Почтовый адрес")').next().text()
        ogrn: ownerPage('td.fname:contains("ОГРН")').next().text()
        fax: ownerPage('td.fname:contains("Факс")').next().text()
        phone: ownerPage('td.fname:contains("Телефон")').next().text()
        email: ownerPage('td.fname:contains("Email")').next().text()
      head = $('td:contains("Извещение о проведении")').last().text().trim()
      trade.number = head.match(/№\s(\d+)/)?[1]
      trade.trade_type = head.match(/(аукцион|конкурс|публичное предложение)/i)?[0].toLowerCase()
      if /Отказ организатора/i.test head
        lot.status = 'Торги отменены'
      else
        now = new Date()
        if now < trade.requests_start_date then lot.status = 'Извещение опубликовано'
        else
          if $('a:contains("Предложения")').next().text().trim() is '- 0' or $('a:contains("Претенденты")').next().text().trim() is '- 0/0'
            lot.status = 'Прием заявок'
          else 'Идут торги'
          if now > trade.holding_date then lot.status = 'Торги завершены'
      lot.number = 1
      lot.title = $('td.fname:contains("реализуемого")').next().find('b').text().trim()
      lot.procedure = "Документы, прилагаемые к заявке: " + $('td.fname:contains("Документы, прилагаемые к заявке:")').next().text()
      lot.category = $('td.fname:contains("Категория имущества")').next().text()
      lot.currency = 'Российская Федерация'
      lot.start_price = math $('td.fname:contains("Начальная цена предмета договора")').next().text()
      lot.information = $('td.fname:contains("реализуемого")').clone().children().remove().end().text().trim()
      lot.information += $('td.fname:contains("реализуемого")').next().find('b').text().trim() + ' '
      lot.information += 'Месторасположение предмета торгов: ' + $('td.fname:contains("Месторасположение предмета торгов:")').next().text()
      lot.step_sum = math $('td.fname:contains("Шаг аукциона")').next().text()
      lot.step_percent = Math.round(lot.step_sum / lot.start_price) * 100
      lot.current_sum = math($('td.fname:contains("Текущая цена")').next().text()) or lot.start_price
      lot.deposit_procedure = $('td.fname:contains("Обеспечение заявок и исполнения договора")').next().text()
      lot.payment_account = $('td.fname:contains("Условия оплаты")').next().text()
      lot.bik = null
      lot.discount = lot.start_price - lot.current_sum
      lot.discount_percent = lot.discount / lot.start_price * 100
      lot.price_reduction_type = null
      lot.calc_method = null
      lot.bank_name = null
      lot.deposit_payment_date = null
      lot.deposit_size = null
      lot.correspondent_account = null
      lot.deposit_return_date = null
      lot.documents = []
      docUrl = 'https://www.fabrikant.ru' + $('a:contains("Документация по торгам")').first().attr('href')
      resp = needle.get.sync null, docUrl, options
      docPage = cheerio.load resp[1]
      docPage('tr.c1').each ->
        lot.documents.push
          name: docPage(@).find('td > a > b').text()
          url: 'https://www.fabrikant.ru' + docPage(@).find('td > a').attr('href')
      lot.intervals = []
      $('td.fname:contains("Понижение цены")').next().clone().children().remove().end().contents().each ->
        lot.intervals.push
          interval_start_date: moment(@data.slice(0, 16), "DD.MM.YYYY HH:mm").toDate()
          request_start_date: moment(@data.slice(0, 16), "DD.MM.YYYY HH:mm").toDate()
          interval_price: math(@data.slice(18, 200))
          price_reduction_percent: (1 - math(@data.slice(18, 200)) / lot.start_price) * 100
      if lot.intervals.length > 0
        for i in [0..lot.intervals.length - 2]
          first  = lot.intervals[i]
          second = lot.intervals[i+1]
          if second?
            first.interval_end_date = first.request_end_date = moment(second.request_start_date).subtract(1, 'seconds').toDate()
            second.deposit_sum = first.interval_price - second.interval_price
        lot.intervals[0].deposit_sum = lot.start_price - lot.intervals[0].interval_price
        lot.intervals[lot.intervals.length-1].interval_end_date = lot.intervals[lot.intervals.length-1].request_end_date = moment(trade.requests_end_date or trade.holding_date).subtract(1, 'seconds').toDate()
      trade.lots = [lot]
      cb null, trade
    catch e then cb e