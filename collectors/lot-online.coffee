needle    = require 'needle'
cheerio   = require 'cheerio'
Sync      = require 'sync'

argv      = require('optimist').argv
amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
request   = require '../downloaders/request'
log       = logger  'LOT-ONLINE LIST COLLECTOR'
config    = require '../config'
etp       = { name: argv.name, href: argv.href, platform: argv.platform }

options =
  proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true

Sync =>
  try
    log.info "Start collecting #{etp.name}"
    stop = ""
    page = parseInt redis.get.sync(null, etp.href) or '0'
    resp = needle.get.sync null, 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml', options
    $ = cheerio.load resp[0].raw.toString()
    cookie = resp[0].headers['set-cookie'][0].match(/^JSESSIONID=([a-zA-Z0-9.]+);/)[1]
    options.cookies = 'JSESSIONID': cookie
    vstate = $('input[id="javax.faces.ViewState"]').val().replace(':', '%3A')
    url = "http://bankruptcy.lot-online.ru/e-auction/lots.xhtml;jsessionid=#{cookie}"
    options.accept = 'application/xml, text/xml, */*; q=0.01'
    options.headers =
      'Content-Type':'application/x-www-form-urlencoded'
      'Faces-Request': 'partial/ajax'
      'DNT':'1'
      'Host':'bankruptcy.lot-online.ru'
      'Origin':'http://bankruptcy.lot-online.ru'
      'Referer':'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml'
      'X-Requested-With':'XMLHttpRequest'
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:switcher-filter&javax.faces.partial.execute=formMain:switcher-filter&javax.faces.partial.render=formMain:switcher-filter formMain:form-filter-tender&formMain:switcher-filter=formMain:switcher-filter"
    resp = needle.post.sync null, url, form, options
    vstate = resp[1]['partial-response'].changes.update[resp[1]['partial-response'].changes.update.length - 1]._.replace(':', '%3A')
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=&formMain%3AcostBValueE=&formMain%3Aj_idt111=&formMain%3AselectIndPublish=2&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:cbFilter&javax.faces.partial.execute=formMain:cbFilter formMain:pgFilterFields&javax.faces.partial.render=formMain:pgFilterFields formMain:panelList formMain:LotListPaginatorID formMain:lotListHeaderPanel&formMain:cbFilter=formMain:cbFilter"
    resp = needle.post.sync null, url, form, options
    vstate = resp[1]['partial-response'].changes.update[resp[1]['partial-response'].changes.update.length - 1]._.replace(':', '%3A')
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=0&formMain%3AcostBValueE=0&formMain%3Aj_idt111=&formMain%3AselectIndPublish=3&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clTable&javax.faces.partial.execute=formMain:clTable&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID formMain:formSelectTableType&formMain:clTable=formMain:clTable"
    resp = needle.post.sync null, url, form, options
    vstate = resp[1]['partial-response'].changes.update[resp[1]['partial-response'].changes.update.length - 1]._.replace(':', '%3A')
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=0&formMain%3AcostBValueE=0&formMain%3Aj_idt111=&formMain%3AselectIndPublish=3&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clPage50&javax.faces.partial.execute=formMain:clPage50&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID formMain:formSelectTableType&formMain:clPage50=formMain:clPage50"
    getter = 1
    last = ''
    while true
      console.log page
      resp = needle.post.sync null, url, form, options
      $ = cheerio.load resp[1]['partial-response'].changes.update[getter]._.toString(), decodeEntities: true
      $('tr').each ->
        number = $(@).find('.field-lot').text()
        url = 'http://bankruptcy.lot-online.ru/e-auction/' + $(@).find('.filed-title').attr('href')
        last = number
        amqp.publish.sync null, config.tradeUrlsQueue, '', headers:
          url: url
          number: number
          etp: etp
          downloader: 'request'
          parser: 'lot-online/trade'
          queue: config.tradeHtmlQueue
      page += 1
      redis.set.sync null, etp.href, page.toString()
      if stop is last then break
      stop = last
      form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=0&formMain%3AcostBValueE=0&formMain%3Aj_idt111=&formMain%3AselectIndPublish=3&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clNext&javax.faces.partial.execute=formMain:clNext&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID&formMain:clNext=formMain:clNext"
      getter = 0
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1
