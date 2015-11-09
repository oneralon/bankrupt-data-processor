needle    = require 'needle'
xml2js    = require 'xml2js'
moment    = require 'moment'
Sync      = require 'sync'
cheerio   = require 'cheerio'

xmlParser = new xml2js.Parser
  explicitArray: no

trim = (text) -> if text? then text.replace(/^\s+/, '').replace(/\s+$/, '') else ''

sleep = (time, cb) -> setTimeout cb, time
get = (url, form, options, cb) ->
  Sync =>
    try
      tries = 0
      sleep.sync null, 100
      resp = needle.post.sync null, url, form, options
      while not resp? or resp[0].raw.toString().length < 405
        if tries > 4 then cb('Error in getting partial/ajax')
        sleep.sync null, 100
        resp = needle.post.sync null, url, form, options
        tries += 1
      sleep.sync null, 100
      needle.post.sync null, url, form, options
      cb null, resp[1]['partial-response'].changes.update[0]._
    catch e then cb e

options =
  proxy: 'http://127.0.0.1:18118'
  compressed: true
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) '
  headers:
    'Accept':'*/*'
    'Content-Type':'application/x-www-form-urlencoded'
    'Faces-Request':'partial/ajax'
    'DNT': '1'
    'Connection': 'close'
    'Origin': 'http://bankruptcy.lot-online.ru'

module.exports = (page, trade, cookies, vstate, cb) ->
  options.cookies = cookies
  options.referer = trade.url
  url = "http://bankruptcy.lot-online.ru/e-auction/auctionLotProperty.xhtml;jsessionid=#{cookies['JSESSIONID']}"
  Sync =>
    try
      # Порядок проведения торгов (421)
      if page('.js:contains("Порядок проведения торгов")').length > 0
        action = page('.js:contains("Порядок проведения торгов")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3ApanelGroupAuctionOrder&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        trade.lots[0].procedure = trade.submission_procedure = trim $('.form-item > label:contains("Порядок оформления участия в торгах, перечень документов участника и требования к оформлению")')?['0']?.next?['data']
        trade.win_procedure = trim $('.form-item > label:contains("Порядок и критерии определения победителя торгов")')?['0']?.next?['data']
        trade.results_place = trim $('.form-item > label:contains("Дата, время и место подведения результатов открытых торгов")')?['0']?.next?['data']
      # Порядок оформления прав победителя (424)
      if page('.js:contains("Порядок оформления прав победителя")').length > 0
        action = page('.js:contains("Порядок оформления прав победителя")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3ApanelGroupWinnerRightsOrder1&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        trade.debtor.contract_procedure = trim $('.form-item > label:contains("Порядок и срок заключения договора купли-продажи имущества (предприятия) должника")')?['0']?.next?['data']
        trade.debtor.payment_terms = trim $('.form-item > label:contains("Сроки платежей, реквизиты счетов, на которые вносятся платежи")')?['0']?.next?['data']
      # Порядок внесения задатка (359)
      if page('.js:contains("Порядок внесения задатка")').length > 0
        action = page('.js:contains("Порядок внесения задатка")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3ApanelGroupDpDepositOrder&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        trade.lots[0].deposit_procedure = trim $('.form-item > label:contains("Порядок внесения и возврата задатка")')?['0']?.next?['data']
        trade.lots[0].payment_account = trim $('.form-item > label:contains("Реквизиты счетов, на которые вносится задаток")')?['0']?.next?['data']
      # Публикации о торгах (428)
      if page('.js:contains("Публикации о торгах")').length > 0
        action = page('.js:contains("Публикации о торгах")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3ApanelGroupPublications&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        trade.official_publish_date = moment(trim $('.form-item > label:contains("Дата публикации в официальном издании")')?['0']?.next?['data'], "DD.MM.YYYY").toDate()
        trade.bankrot_date = moment(trim $('.form-item > label:contains("Дата публикации в Едином федеральном реестре")')?['0']?.next?['data'], "DD.MM.YYYY").toDate()
      # Арбитражный управляющий (416)
      if page('.js:contains("Арбитражный управляющий")').length > 0
        action = page('.js:contains("Арбитражный управляющий")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3ApanelGroupArbitrManager&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        lastname = trim $('.form-item > label:contains("Фамилия")')?['0']?.next?['data']
        name = trim $('.form-item > label:contains("Имя")')?['0']?.next?['data']
        fathersname = trim $('.form-item > label:contains("Отчество")')?['0']?.next?['data']
        trade.debtor.arbitral_commissioner = lastname + ' ' + name + ' ' + fathersname
        trade.debtor.arbitral_organization = trim $('.form-item > label:contains("СРО")')?['0']?.next?['data']
      # Порядок ознакомления с имуществом
      if page('.js:contains("Порядок ознакомления с имуществом")').length > 0
        action = page('.js:contains("Порядок ознакомления с имуществом")').attr('id').replace(':', '%3A')
        $ = cheerio.load get.sync(null, url, "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.source=#{action}&javax.faces.partial.event=click&javax.faces.partial.execute=#{action}%20#{action}&javax.faces.partial.render=formMain%3AexcurseInfo&javax.faces.behavior.event=action&javax.faces.partial.ajax=true", options).toString(), decodeEntities: true
        trade.debtor.reviewing_property = $('#excurse-info').text().trim()
      return cb null, trade
    catch e then cb(e)