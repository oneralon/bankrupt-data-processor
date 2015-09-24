_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
jsdom     = require 'node-jsdom'
Sync      = require 'sync'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'U-TRADE TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

lotParser = require './lot'

module.exports = (html, etp, url, ismicro, cb) ->
  log.info "Parse trade #{url}"

  id = url.match(/id=(\d+)/i)[1]

  last = html.lastIndexOf('</table>') + 8

  substr = html.length - last

  html = html.substr(0, html.length - substr) + '</body></html>'

  $ = cheerio.load html

  deposit_procedure = $("th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Сроки и порядок внесения и возврата задатка, реквизиты счетов, на которые вносится задаток')").first().next().text().trim()
  trade = {}
  trade.url = url
  trade.title = $("h1:contains('идентификационный номер:')").first().text().trim()
  trade.holding_date = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Дата и время подведения результатов торгов')").first().next().text().trim()
  trade.holding_date = moment(trade.holding_date, "DD.MM.YYYY HH:mm")
  trade.membership_type = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Форма проведения торгов и подачи предложений')").first().next().text().trim()
  trade.submission_procedure = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Порядок, место, срок и время представления заявок на участие в торгах и предложений о цене имущества (предприятия) должника')").first().next().text().trim()
  trade.win_procedure = $("th:contains('Определение победителей')").first().parent().parent().parent().find("td:contains('Порядок и критерии определения победителей торгов')").first().next().text().trim()
  trade.bankrot_date = $("th:contains('Дополнительные сведения')").first().parent().parent().parent().find("td:contains('Дата размещения сообщения в Едином Федеральном Реестре сведений о банкротстве')").first().next().text().trim()
  trade.bankrot_date = moment(trade.bankrot_date, "DD.MM.YYYY")
  trade.official_publish_date = $("th:contains('Дополнительные сведения')").first().parent().parent().parent().find("td:contains('Дата публикации сообщения о проведении торгов в официальном издании')").first().next().text().trim()
  trade.official_publish_date = moment(trade.official_publish_date, "DD.MM.YYYY")
  trade.requests_start_date = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Начало предоставления заявок на участие')").first().next().text().trim()
  trade.requests_start_date = moment(trade.requests_start_date, "DD.MM.YYYY HH:mm")
  trade.requests_end_date = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Окончание предоставления заявок на участие')").first().next().text().trim()
  trade.requests_end_date = moment(trade.requests_end_date, "DD.MM.YYYY HH:mm")
  trade.results_place = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Место подведения результатов торгов')").first().next().text().trim()
  trade.additional = $("#info > div > table > thead > tr > th:contains('Информация о торгах')").first().parent().parent().parent().find("td:contains('Порядок оформления участия в торгах, перечень представляемых участниками торгов документов и требования к их оформлению')").first().next().text().trim()
  trade.owner = {}
  trade.owner.full_name = $("th:contains('Организатор торгов')").first().parent().parent().parent().find("td:contains('Наименование')").first().next().text().trim()
  trade.owner.short_name = trade.owner.full_name
  trade.owner.contact =
    email: $("th:contains('Организатор торгов')").first().parent().parent().parent().find("td:contains('Адрес электронной почты')").first().next().text().trim()
    phone: $("th:contains('Организатор торгов')").first().parent().parent().parent().find("td:contains('Номер контактного телефона')").first().next().text().trim()
  trade.debtor = {}
  trade.debtor.judgment = $("th:contains('Сведения о банкротстве')").first().parent().parent().parent().find("td:contains('Основание для проведения торгов')").first().next().text().trim()
  trade.debtor.full_name = $("th:contains('Сведения о должнике')").first().parent().parent().parent().find("td:contains('Полное наименование')").first().next().text().trim()
  trade.debtor.short_name = $("th:contains('Сведения о должнике')").first().parent().parent().parent().find("td:contains('Краткое наименование')").first().next().text().trim()
  trade.debtor.ogrn = $("th:contains('Сведения о должнике')").first().parent().parent().parent().find("td:contains('ОГРН')").first().next().text().trim()
  trade.debtor.inn = $("th:contains('Сведения о должнике')").first().parent().parent().parent().find("td:contains('ИНН')").first().next().text().trim()
  trade.debtor.payment_terms = $("th:contains('Договор купли-продажи')").first().parent().parent().parent().find("td:contains('Сроки платежей, реквизиты счетов, на которые вносятся платежи')").first().next().text().trim()
  trade.debtor.contract_procedure = $("th:contains('Договор купли-продажи')").first().parent().parent().parent().find("td:contains('Порядок и срок заключения договора купли-продажи')").first().next().text().trim()
  trade.debtor.arbitral_organization = $("th:contains('Арбитражный управляющий')").first().parent().parent().parent().find("td:contains('Название саморегулируемой организации арбитражных управляющих')").first().next().text().trim()
  trade.debtor.arbitral_commissioner = $("th:contains('Арбитражный управляющий')").first().parent().parent().parent().find("td:contains('Фамилия, имя, отчество')").first().next().text().trim()
  trade.debtor.arbitral_name = $("th:contains('Сведения о банкротстве')").first().parent().parent().parent().find("td:contains('Наименование арбитражного суда')").first().next().text().trim()
  trade.debtor.bankruptcy_number = $("th:contains('Сведения о банкротстве')").first().parent().parent().parent().find("td:contains('Номер дела о банкротстве')").first().next().text().trim()

  docs = []
  docs_rows = $("a[href*='/files/download/']")
  for doc in docs_rows
    name = $(doc).text().trim()
    url = etp.href.match(host)[0] + $(doc).attr('href')
    docs.push { name: name, url: url }
  trade.documents = docs

  log.info 'Parsed information'

  pages = $('.paginatorNotSelectedPage')
  if pages.length is 0
    pages = 1
  else
    pages = parseInt($(pages[pages.length -1]).text() or '1')
  lots = []

  log.info "Trade has #{pages} pages"

  for page in [1..pages]
    pageUrl = etp.href.match(host)[0] + "/etp/trade/inner-view-lots.html?id=#{id}&page=#{page}"
    lots.push new Promise (resolve, reject) ->
      Sync =>
        try
          additional =
            deposit_procedure: deposit_procedure
            procedure: additional
            currency: 'Российская Федерация'
            category: 'Не определена'
          html = request.sync null, pageUrl
          lot = lotParser html, etp, additional
          resolve(lot)
        catch e then reject e
  Promise.all(lots).catch(cb).then (lot_chunks) ->
    trade.lots = []
    for chunk in lot_chunks
      for lot in chunk
        lot.url = if lot.url? then lot.url.replace '//www.', '//' else trade.url.replace '//www.', '//'
        trade.lots.push lot
    cb null, trade