_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'

request   = require '../../downloaders/request'
parseLot  = require './lot'
logger    = require '../../helpers/logger'
status    = require '../../helpers/status'
log       = logger  'I-TENDER TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

fieldsets = require './trade-fieldset'
collector = require './lots-collector'

publish = (container, url, etp) ->
  container.push new Promise (resolve, reject) ->
    request url, (err, resp) ->
      unless err?
        lot = parseLot resp[0], etp
        lot.url = url.replace '//www.', '//'
        log.info "Resolved #{url}"
        resolve(lot)
      else
        log.error "Resolved #{url}"
        resolve()

module.exports = (html, etp, url, ismicro, cb) ->
  $ = cheerio.load(html)
  log.info "Parse trade #{url}"
  trade = {}
  trade.etp = etp
  trade.url = url
  trade_type = $('legend:contains("№")').text().trim()
  if /аукцион/i.test(trade_type)
    trade.trade_type = 'аукцион'
    trade_form = $('td.tdTitle:contains("Форма торга по составу участников")').next().text()
    trade_form = if /открыт/i.test(trade_form) then 'Открытый' else 'Закрытый'
    trade_reqt = $('td.tdTitle:contains("Форма представления предложений о цене")').next().text()
    trade_reqt = if /открыт/i.test(trade_form) then 'открытой' else 'закрытой'
    trade.type = [trade_form, trade.trade_type, 'c', trade_reqt, 'формой представления предложений о цене'].join(' ')
  if /публичном предложении/i.test(trade_type)
    trade.trade_type = 'публичное предложение'
    trade_form = $('td.tdTitle:contains("Форма торга по составу участников")').next().text()
    trade_form = if /открыт/i.test(trade_form) then 'Открытое' else 'Закрытое'
    trade_reqt = $('td.tdTitle:contains("Форма представления предложений о цене")').next().text()
    trade_reqt = if /открыт/i.test(trade_form) then 'открытой' else 'закрытой'
    trade.type = [trade_form, trade.trade_type, 'c', trade_reqt, 'формой представления предложений о цене'].join(' ')
  if /конкурсе/i.test(trade_type)
    trade.trade_type = 'конкурс'
    trade_form = $('td.tdTitle:contains("Форма торга по составу участников")').next().text()
    trade_form = if /открыт/i.test(trade_form) then 'Открытый' else 'Закрытый'
    trade_reqt = $('td.tdTitle:contains("Форма представления предложений о цене")').next().text()
    trade_reqt = if /открыт/i.test(trade_form) then 'открытой' else 'закрытой'
    trade.type = [trade_form, trade.trade_type, 'c', trade_reqt, 'формой представления предложений о цене'].join(' ')
  trade.trade_type = ''
  fieldset = $("fieldset").filter(->
    /информация о(б аук| пуб| кон)/i.test $(@).find("legend").text().trim()
  ).find("td.tdTitle")
  .add $("fieldset").filter(->
    /подведение результатов/i.test $(@).find("legend").text().trim()
  ).find("td.tdTitle")
  .add $("fieldset").filter(->
    /подписывающее договор/i.test $(@).find("legend").text().trim()
  ).find("td.tdTitle")
  fieldset.each () ->
    field = _.where(fieldsets.info, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          trade[field.field] = value.trim()
          if field.params?.lower_case
            trade[field.field] = value?.trim().toLowerCase()
          break
        when Date
          switch value.length
            when 16
              format = "DD.MM.YYYY HH:mm"
              break
            when 10
              format = "DD.MM.YYYY"
              break
          if value.length < 10
            console.log $(@).next().html()
          date = moment(value, format)
          trade[field.field] = if date.isValid() then date.format() else undefined
          break
  fieldset = $('fieldset').filter( -> $(@).find('legend').text().trim() is 'Документы').find('tr.gridRow td a:not([href="#"])')
  trade.documents = []
  fieldset.each ->
    trade.documents.push {
      url: etp.href.match(host)[0] + $(@).attr('href')
      name: $(@).text()
    }
  fieldset = $("fieldset").filter(->
    /информация о должнике/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  trade.debtor = {}
  fieldset.each () ->
    field = _.where(fieldsets.debtor, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          trade.debtor[field.field] = value.trim()
          break
        when Date
          switch value.length
            when 16
              format = "DD.MM.YYYY HH:mm"
              break
            when 10
              format = "DD.MM.YYYY"
              break
          date = moment(value, format)
          trade.debtor[field.field] = if date.isValid() then date.format() else undefined
          break

  fieldset = $("fieldset").filter(->
    /организатор торгов/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  trade.owner = {}
  fieldset.each () ->
    field = _.where(fieldsets.owner, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text().trim()
      switch field.type
        when String
          trade.owner[field.field] = value.trim()
          break
        when Date
          switch value.length
            when 16
              format = "DD.MM.YYYY HH:mm"
              break
            when 10
              format = "DD.MM.YYYY"
              break
          date = moment(value, format)
          trade.owner[field.field] = if date.isValid() then date.format() else undefined
          break
  fieldset = $("fieldset").filter(->
    /контактное лицо организатора торгов/i.test $(this).find("legend").text().trim()
  ).find("td.tdTitle")
  trade.owner.contact = {}
  fieldset.each () ->
    field = _.where(fieldsets.contact, title: $(@).text().replace(/(:|\(\*\))/g, '').trim())?[0]
    if field?
      value = $(@).next().find('span').eq(0).text()
      switch field.type
        when String
          trade.owner.contact[field.field] = value.trim()
          break
        when Date
          switch value.length
            when 16
              format = "DD.MM.YYYY HH:mm"
              break
            when 10
              format = "DD.MM.YYYY"
              break
          date = moment(value, format)
          trade.owner.contact[field.field] = if date.isValid() then date.format() else undefined
          break

  promises = []
  urls = []
  lotsJQ = $("table[id*='ctl00_ctl00_MainContent_ContentPlaceHolderMiddle_ctl00_srLots'] tr:not([class='gridHeader'])")
  for lotJQ in lotsJQ
    rel = $(lotJQ).find('td.gridAltColumn a').attr('href')
    urls.push etp.href.match(host)[0] + rel if rel?
  if true or $("table[id*='ctl00_ctl00_MainContent_ContentPlaceHolderMiddle_ctl00_srLots'] .pager span:not(:contains('Страницы:'))").next("a:not(:contains('<<'))").length is 0
    for lotUrl in urls
      publish promises, lotUrl, etp
    Promise.all(promises).then (lots) ->
      trade.lots = lots
      cb null, trade
  else
    log.info 'More than 50 lots in trade'
    collector.collect url, (err, relatives) ->
      cb err if err?
      for rel in relatives
        urls.push etp.href.match(host)[0] + rel
      for lotUrl in urls
        publish promises, lotUrl, etp
      collector.phantom.exit()
      Promise.all(promises).then (lots) ->
        for lot in lots
          if lot.status then lot.status = status(lot.status)
        trade.lots = lots
        cb null, trade