_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
regionize = require '../../helpers/regionize'
status    = require '../../helpers/status'
log       = logger  'FABRIKANT TRADE PARSER'
config    = require '../../config'
host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

lotParser = require './lot'

module.exports = (html, etp, url, ismicro, cb) ->
  log.info "Parse trade #{url}"
  trade = {}
  trade.url = url
  trade.etp = etp

  $ = cheerio.load html

  trade.title = title = $('body > table:nth-child(2) > tbody > tr > td > table:nth-child(6) > tbody > tr > td.body_text > table > tbody > tr:nth-child(1) > td > table > tbody > tr > td:nth-child(1)').text().trim()
  trade.type = $('td.fname:contains("Форма аукциона")').next().text()
  trade.trade_type = title.match(/(аукцион|конкурс|публичное предложение)/i)[0].toLowerCase()
  trade.membership_type = if /Открытый/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.price_submission_type = if /открытой/.test(trade.type) then 'Открытая' else 'Закрытая'
  trade.win_procedure = $('td.fname:contains("Порядок и критерии выявления победителя")').next().text()
  trade.submission_procedure = $('td.fname:contains("Порядок подачи заявок на участие")').next().text()
  trade.holding_date = moment $('td.fname:contains("Дата и время подведения итогов")').next().text(), "DD.MM.YYYY HH:mm"
  trade.official_publish_date = moment $('td.fname:contains("Дата публикации в печатных СМИ")').next().text().match(/от (.+)$/)?[1], "DD.MM.YYYY"
  trade.print_publish_date =  moment $('td.fname:contains("Дата публикации в печатных СМИ по месту нахождения должника")').next().text().match(/от (.+)$/)?[1], "DD.MM.YYYY"
  trade.results_place = $('td.fname:contains("Место проведения")').next().text()
  trade.results_date = moment $('td.fname:contains("Дата подведения результатов торгов")').next().text(), "DD.MM.YYYY HH:mm"
  # trade.additional

  trade.debtor = {}
  trade.debtor.inn = $('td.fname:contains("Должник")').next().text().match(/ИНН:\s(\d+)/)[1]
  trade.debtor.short_name = $('td.fname:contains("Должник")').next().text().match(/(.+)\(/)[1]
  trade.debtor.full_name = $('td.fname:contains("Должник")').next().text().match(/(.+)\(/)[1]
  trade.debtor.ogrn = $('td.fname:contains("Должник")').next().text().match(/ОГРН:\s(\d+)/)[1]
  trade.debtor.judgment
  trade.debtor.reviewing_property = $('td.fname:contains("Порядок ознакомления с имуществом")').next().text()
  trade.debtor.region = regionize trade
  trade.debtor.arbitral_name = $('td.fname:contains("Наименование арбитражного суда")').next().text()
  trade.debtor.bankruptcy_number = $('td.fname:contains("Номер дела о банкротстве")').next().text()
  trade.debtor.arbitral_commissioner = $('td.fname:contains("Арбитражный управляющий")').next().text().match(/(.+)\(/)[1].trim()
  trade.debtor.arbitral_organization = $('td.fname:contains("членом которой является арбитражный управляющий")').next().text()
  trade.debtor.contract_procedure = $('td.fname:contains("Порядок и сроки заключения договора ")').next().text()
  trade.debtor.payment_terms = $('td.fname:contains("Условия оплаты")').next().text()

  trade.owner = {}
  trade.owner.short_name = $('td.fname:contains("Организатор процедуры:")').next().find('a').text()
  trade.owner.full_name = $('td.fname:contains("Организатор процедуры:")').next().find('a').text()
  # trade.owner.internet_address
  # trade.owner.inn
  # trade.owner.kpp
  # trade.owner.ogrn
  # trade.owner.ogrnip

  trade.contact = name: $('td.fname:contains("Контактное лицо:")').next().html().split('<br>').join(', ')

  lotParser html, etp, url, (err, lot) ->
    trade.lots = [lot]
    #trade.intervals_start_date from lot
    #trade.interval_end_date from lot

    cb null, trade