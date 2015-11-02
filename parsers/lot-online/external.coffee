needle    = require 'needle'
xml2js    = require 'xml2js'
moment    = require 'moment'
Sync      = require 'sync'
cheerio   = require 'cheerio'

xmlParser = new xml2js.Parser
  explicitArray: no

options =
  # proxy: 'http://127.0.0.1:18118'
  compressed: true
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  headers:
    'Accept':'*/*'
    'Content-Type':'application/x-www-form-urlencoded'
    'Faces-Request':'partial/ajax'
    'DNT': '1'
    'Connection': 'keep-alive'
    'Origin': 'http://bankruptcy.lot-online.ru'

module.exports = (trade, cookies, vstate, cb) ->
  options.cookies = cookies
  options.headers['Referer'] = trade.url
  url = "http://bankruptcy.lot-online.ru/e-auction/auctionLotProperty.xhtml;jsessionid=#{cookies['JSESSIONID']}"
  Sync =>
    try
      form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=formMain%3AclDpExpEvent1&javax.faces.partial.event=click&javax.faces.partial.execute=formMain%3AclDpExpEvent1%20formMain%3AclDpExpEvent1&javax.faces.partial.render=formMain%3AexcurseInfo&javax.faces.behavior.event=action&javax.faces.partial.ajax=true"
      resp = needle.post.sync null, url, form, options
      $ = cheerio.load resp[1]['partial-response'].changes.update[0]._
      trade.debtor.reviewing_property = $('#excurse-info').text().trim()
      resp = needle.post.sync null, url, form, options
      form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=formMain%3Aj_idt359&javax.faces.partial.event=click&javax.faces.partial.execute=formMain%3Aj_idt359%20formMain%3Aj_idt359&javax.faces.partial.render=formMain%3ApanelGroupDpDepositOrder&javax.faces.behavior.event=action&javax.faces.partial.ajax=true"
      resp = needle.post.sync null, url, form, options
      $ = cheerio.load resp[1]['partial-response'].changes.update[0]._, decodeEntities: true
      trade.lots[0].deposit_procedure = $('.form-item')['0'].children[1].next['data'].replace(/^\s+/, '').replace(/\s+$/, '')
      trade.lots[0].payment_account = $('.form-item')['1'].children[1].next['data'].replace(/^\s+/, '').replace(/\s+$/, '')
      resp = needle.post.sync null, url, form, options
      cb null, trade
    catch e then cb(e)