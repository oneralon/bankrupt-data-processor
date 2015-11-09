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

lotParser = require './lot'

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
    parseFloat(text.match(/(.+)руб/)[1].replace(/\s/g, '').replace(',','.'))
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
      trade.debtor = {}
      trade.debtor.full_name = $('td.fname:contains("Должник")').next().text().match(/(.+)\(/)[1]
      trade.debtor.short_name = null
      trade.debtor.inn = $('td.fname:contains("Должник")').next().text().match(/ИНН:\s(\d+)/)[1]
      trade.debtor.ogrn = $('td.fname:contains("Должник")').next().text().match(/ОГРН:\s(\d+)/)[1]
      trade.debtor.arbitral_commissioner = $('td.fname:contains("Арбитражный управляющий")').next().text().match(/(.+)\(/)[1].trim()
      trade.debtor.arbitral_name = $('td.fname:contains("Наименование арбитражного суда")').next().text()
      trade.debtor.bankruptcy_number = $('td.fname:contains("Номер дела о банкротстве")').next().text()
      trade.debtor.reviewing_property = $('td.fname:contains("Порядок ознакомления с имуществом")').next().text()
      trade.debtor.arbitral_organization = $('td.fname:contains("членом которой является арбитражный управляющий")').next().text()
      trade.debtor.contract_procedure = $('td.fname:contains("Порядок и сроки заключения договора ")').next().text()
      trade.debtor.payment_terms = lot.payment_account = $('td.fname:contains("Условия оплаты")').next().text()
      trade.debtor.judgment = null
      trade.debtor.debtor_type = 'Не определен'
      if /(ООО|АО|ЗАО|ПАО|ОАО|ГУП|ФГУП|МУП)/i.test trade.debtor.full_name then trade.debtor.debtor_type = 'Юридическое лицо'
      if /(ПБОЮЛ|ИП)/i.test trade.debtor.full_name then trade.debtor.debtor_type = 'Индивидуальный предприниматель'
      trade.bankrot_date = null
      trade.contract_signing_person = $('td.fname:contains("Организатор процедуры")').next().find('a').text()
      ownerUrl = 'https://www.fabrikant.ru' + $('td.fname:contains("Организатор процедуры")').next().find('a').attr('href')
      # resp = needle.get.sync null, ownerUrl, options
      # ownerPage = cheerio.load resp[1]
      # trade.owner = {}
      # trade.owner.short_name = ownerPage('td.fname:contains("Краткое наименование организации")').next().text()
      # trade.owner.full_name = ownerPage('td.fname:contains("Полное наименование организации")').next().text()
      # trade.owner.internet_address = ownerPage('td.fname:contains("Адрес корпоративного web-сайта")').next().text()
      # trade.owner.contact =
      #   name: $('td.fname:contains("Организатор процедуры")').next().find('a').text()
      #   address: ownerPage('td.fname:contains("Почтовый адрес")').next().text()
      #   ogrn: ownerPage('td.fname:contains("ОГРН")').next().text()
      #   fax: ownerPage('td.fname:contains("Факс")').next().text()
      #   phone: ownerPage('td.fname:contains("Телефон")').next().text()
      #   email: ownerPage('td.fname:contains("Email")').next().text()

      head = $('td:contains("Извещение о проведении")').last().text().trim()
      console.log head
      trade.number = head.match(/№\s(\d+)/)?[1]
      trade.trade_type = head.match(/(аукцион|конкурс|публичное предложение)/i)[0].toLowerCase()
      if /Отказ организатора/i.test head
        trade.status = 'Торги отменены'
      # else

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

      trade.lots = [lot]




      console.log trade

      # trade.results_date = moment($('td.fname:contains("Дата подведения результатов торгов")').next().text().trim(), "DD.MM.YYYY HH:mm").toDate()

      # # trade.additional

      # trade.owner.internet_address
      # trade.owner.inn
      # trade.owner.kpp
      # trade.owner.ogrn
      # trade.owner.ogrnip
      e()
      cb null, trade
    catch e then cb e