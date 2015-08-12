_         = require 'lodash'
cheerio   = require 'cheerio'
moment    = require 'moment'
Promise   = require 'promise'

request   = require '../../downloaders/request'
parseLot  = require './lot'
logger    = require '../../helpers/logger'
log       = logger  'I-TENDER TRADE PARSER'
config    = require '../../config'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

fieldsets = require './trade-fieldset'

module.exports = (html, etp, cb) ->
  $ = cheerio.load(html)
  promises = urls = []
  lotsJQ = $("table[id*='ctl00_ctl00_MainContent_ContentPlaceHolderMiddle_ctl00_srLots'] tr:not([class='gridHeader'])")
  for lotJQ in lotsJQ
    url = etp.url.match(host)[0] + $(lotJQ).find('td.gridAltColumn a').attr('href')
    promises.push new Promise (resolve) ->
      request url, (err, html) ->
        cb err if err?
        lot = parseLot html, etp
        resolve(lot)
  trade = {}
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
          date = moment(value, format)
          trade[field.field] = if date.isValid() then date.format() else undefined
          break
  fieldset = $('fieldset').filter( -> $(@).find('legend').text().trim() is 'Документы').find('tr.gridRow td a:not([href="#"])')
  trade.documents = []
  fieldset.each ->
    trade.documents.push {
      url: etp.url.match(host)[0] + $(@).attr('href')
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

  Promise.all(promises).then (lots) ->
    trade.lots = lots
    cb null, trade