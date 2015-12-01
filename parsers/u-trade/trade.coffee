_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
needle    = require 'needle'
Promise   = require 'promise'
Sync      = require 'sync'

iconv     = require 'iconv-lite'

request   = require '../../downloaders/request'
logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'U-TRADE TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

lotParser = require './lot'

module.exports = (html, etp, url, headers, cb) ->
  log.info "Parse trade #{url}"
  tradeUrl = url
  last = html.lastIndexOf('</table>') + 8

  substr = html.length - last

  html = html.substr(0, html.length - substr) + '</body></html>'

  id = url.match(/id=(\d+)/i)?[1]

  $ = cheerio.load html,
    xmlMode: true
    decodeEntities: false
    recognizeCDATA: true
    recognizeSelfClosing: true

  deposit_procedure = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Сроки и порядок внесения и возврата задатка, реквизиты счетов, на которые вносится задаток')")?.next().text().trim()
  trade = {}
  trade.etp = etp
  trade.url = url
  trade.type = $('td:contains("Форма проведения торгов и подачи предложений")').next().text().trim()
  if trade.type is ''
    num = headers.number
    trade.type = if num[num.length-4] is 'О' then 'Открытый ' else 'Закрытый '
    trade.type += if num[num.length-3] is 'А' then 'аукцион с ' else 'торг посредством публичного предложения с '
    trade.type += if num[num.length-2] is 'О' then 'открытой ' else 'закрытой '
    trade.type += 'формой предоставления заявок'
  if /аукцион/i.test(trade.type)
    trade.trade_type = 'аукцион'
  if /публичное предложение/i.test(trade.type) or /публичного предложения/i.test(trade.type)
    trade.trade_type = trade.trade_type = 'публичное предложение'
  if /конкурс/i.test(trade.type)
    trade.trade_type = 'конкурс'
  trade.title = $("h1:contains('идентификационный номер:'),h3:contains('идентификационный номер:'),h2.views-style:contains('дентификационный номер')")?.text().trim()
  trade.holding_date = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Дата и время подведения результатов торгов')")?.next().text().trim()
  trade.holding_date = moment(trade.holding_date, "DD.MM.YYYY HH:mm").toDate()
  trade.membership_type = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Форма проведения торгов и подачи предложений')")?.next().text().trim()
  trade.submission_procedure = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Порядок, место, срок и время представления заявок на участие в торгах и предложений о цене имущества')")?.next().text().trim() or $("td:contains('Порядок оформления участия в торгах, перечень представляемых участниками торгов документов и требования к их оформлению')")?.next().first().text().trim()
  trade.win_procedure = $("th:contains('Определение победителей')")?.parent().parent().parent().find("td:contains('Порядок и критерии определения победителей торгов')")?.next().text().trim() or $("td:contains('Порядок и критерии определения победителя торгов')")?.next().text().trim()
  trade.bankrot_date = $("th:contains('Дополнительные сведения')")?.parent().parent().parent().find("td:contains('Дата размещения сообщения в Едином Федеральном Реестре сведений о банкротстве')")?.next().text().trim()
  trade.bankrot_date = moment(trade.bankrot_date, "DD.MM.YYYY").toDate()
  trade.official_publish_date = $("th:contains('Дополнительные сведения')")?.parent().parent().parent().find("td:contains('Дата публикации сообщения о проведении торгов в официальном издании')")?.next().text().trim()
  trade.official_publish_date = moment(trade.official_publish_date, "DD.MM.YYYY").toDate()
  trade.requests_start_date = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Начало предоставления заявок на участие')")?.next().text().trim()
  trade.requests_start_date = moment(trade.requests_start_date, "DD.MM.YYYY HH:mm").toDate()
  trade.requests_end_date = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Окончание предоставления заявок на участие')")?.next().text().trim()
  trade.requests_end_date = moment(trade.requests_end_date, "DD.MM.YYYY HH:mm").toDate()
  trade.results_place = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Место подведения результатов торгов')")?.next().text().trim()
  trade.additional = $("th:contains('Информация о торгах')")?.parent().parent().parent().find("td:contains('Порядок оформления участия в торгах, перечень представляемых участниками торгов документов и требования к их оформлению')")?.next().text().trim()
  trade.owner = {}
  trade.owner.full_name = $("th:contains('Организатор торгов'), th:contains('Информация об организаторе')")?.parent().parent().parent().find("td:contains('Наименование'), td:contains('Полное наименование')")?.next().text().trim()
  if trade.owner.full_name is ''
    $("th:contains('Организатор торгов'), th:contains('Информация об организаторе')").parent().parent().parent().find("td:contains('Фамилия'), td:contains('Имя'), td:contains('Отчество')").next().each -> trade.owner.full_name += $(@).text() + ' '
  trade.owner.full_name = trade.owner.full_name.trim()
  trade.owner.short_name = trade.owner.full_name
  trade.owner.contact =
    email: $("th:contains('Организатор торгов'), th:contains('Информация об организаторе')")?.parent().parent().parent().find("td:contains('Адрес электронной почты')")?.next().text().trim()
    phone: $("th:contains('Организатор торгов'), th:contains('Информация об организаторе')")?.parent().parent().parent().find("td:contains('Номер контактного телефона'), td:contains('Телефон\\Факс')")?.next().text().trim()
  trade.debtor = {}
  trade.debtor.judgment = $("th:contains('Сведения о банкротстве')")?.parent().parent().parent().find("td:contains('Основание для проведения торгов')")?.next().text().trim() or $("td:contains('Основание для проведения')").next().first().text().trim()
  trade.debtor.full_name = $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('Полное наименование')")?.next().text().trim() or $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('Фамилия, имя, отчество')")?.next().text().trim() or $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('ФИО')")?.next().text().trim()
  trade.debtor.short_name = $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('Краткое наименование'), td:contains('Сокращенное наименование')")?.next().text().trim()
  trade.debtor.ogrn = $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('ОГРН')")?.next().text().trim()
  trade.debtor.inn = $("th:contains('Сведения о должнике')")?.parent().parent().parent().find("td:contains('ИНН')")?.next().text().trim()
  trade.debtor.payment_terms = $("th:contains('Договор купли-продажи')")?.parent().parent().parent().find("td:contains('Сроки платежей, реквизиты счетов, на которые вносятся платежи')")?.next().text().trim() or $("td:contains('Сроки платежей, реквизиты счетов')")?.next().first().text().trim()
  trade.debtor.contract_procedure = $("th:contains('Договор купли-продажи')")?.parent().parent().parent().find("td:contains('Порядок и срок заключения договора купли-продажи')")?.next().text().trim()  or $("td:contains('Порядок и срок заключения договора купли-продажи')")?.next().first().text().trim()
  trade.debtor.arbitral_organization = $("th:contains('Арбитражный управляющий')")?.parent().parent().parent().find("td:contains('Название саморегулируемой организации арбитражных управляющих')")?.next().text().trim() or $("td:contains('Организация арбитражных управляющих')")?.next().first().text().trim()
  trade.debtor.arbitral_commissioner = $("th:contains('Арбитражный управляющий')")?.parent().parent().parent().find("td:contains('ФИО')")?.next().text().trim() or $("th:contains('Арбитражный управляющий')")?.parent().parent().parent().find("td:contains('Фамилия, имя, отчество')")?.next().text().trim() or $("td:contains('Арбитражный управляющий')")?.next().first().text().trim()
  trade.debtor.arbitral_name = $("th:contains('Сведения о банкротстве')")?.parent().parent().parent().find("td:contains('Наименование арбитражного суда')")?.next().text().trim() or $("td:contains('Наименование арбитражного суда')")?.next().first().text().trim()
  trade.debtor.bankruptcy_number = $("th:contains('Сведения о банкротстве')")?.parent().parent().parent().find("td:contains('Номер дела о банкротстве')")?.next().text().trim() or $("td:contains('Номер дела о банкротстве')")?.next().first().text().trim()

  docs = []
  docs_rows = $("a[href*='download/']")
  for doc in docs_rows
    name = $(doc).text().trim()
    url = etp.href.match(host)[0] + $(doc).attr('href')
    docs.push { name: name, url: url }
  trade.documents = docs
  log.info 'Parsed information'
  lots = []
  additional =
    deposit_procedure: deposit_procedure
    procedure: trade.additional
    currency: 'Российская Федерация'
    category: 'Не определена'
  if id?
    needle.get etp.href.match(host)[0] + "/etp/trade/inner-view-lots.html?id=#{id}&page=1", (err, res, body) ->
      if res.statusCode isnt 404
        fPage = cheerio.load body
        pages = fPage('.paginatorNotSelectedPage')
        if pages.length is 0
          pages = 1
        else
          pages = parseInt(fPage('.paginatorNotSelectedPage').last().text() or '1')
      else
        pages = 1
      log.info "Trade has #{pages} pages"
      if pages is 1 and $("table[id*=lotNumber], table.data:contains('Лот №'), table.data:contains('Сведения о предмете торгов'), table.data:contains('Информация о предмете торгов'), table:contains('Сведения по лоту №')").length > 0
        lots = lotParser html, etp, additional
        trade.lots = lots
        log.info "Found #{trade.lots.length} lots"
        cb "No lots! #{url}" if trade.lots.length is 0
        cb null, trade
      else
        for page in [1..pages]
          pageUrl = etp.href.match(host)[0] + "/etp/trade/inner-view-lots.html?id=#{id}&page=#{page}"
          lots.push new Promise (resolve, reject) ->
            Sync =>
              try
                resp = request.sync null, pageUrl
                lot = lotParser resp[0], etp, additional
                resolve(lot)
              catch e then reject e
        Promise.all(lots).catch(cb).then (lot_chunks) ->
          trade.lots = []
          for chunk in lot_chunks
            for lot in chunk
              lot.url = if lot.url? then lot.url.replace '//www.', '//' else trade.url.replace '//www.', '//'
              trade.lots.push lot
          log.info "Found #{trade.lots.length} lots"
          cb "No lots! #{tradeUrl}" if trade.lots.length is 0
          cb null, trade
  else
    lots = lotParser html, etp, additional
    console.log trade
    trade.lots = lots
    log.info "Found #{trade.lots.length} lots"
    cb "No lots! #{url}" if trade.lots.length is 0
    # cb null, trade
