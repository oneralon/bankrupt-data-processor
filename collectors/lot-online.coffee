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
  headers:
    'Content-Type':'application/x-www-form-urlencoded'
    'Faces-Request':'partial/ajax'
    'Referer':'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml'

Sync =>
  try
    log.info "Start collecting #{etp.name}"
    page = parseInt redis.get.sync(null, etp.href) or '0'
    html = needle.get.sync null, 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml', options
    $ = cheerio.load html[1]
    options.cookies = 'JSESSIONID': html[0].headers['set-cookie'][0].match(/^JSESSIONID=([a-zA-Z0-9.]+);/)[1]
    vstate = $('input[id="javax.faces.ViewState"]').val().replace(':', '%3A')
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=&formMain%3AcostBValueE=&formMain%3Aj_idt111=&formMain%3AselectIndPublish=3&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:cbFilter&javax.faces.partial.execute=formMain:cbFilter formMain:pgFilterFields&javax.faces.partial.render=formMain:pgFilterFields formMain:panelList formMain:LotListPaginatorID formMain:lotListHeaderPanel&formMain:cbFilter=formMain:cbFilter"
    while true
      resp = needle.post.sync null, etp.href, form, options
      $ = cheerio.load resp[1]['partial-response'].changes.update[1]._
      $('td[class="ui-datagrid-column"]').each ->
        number = $(@).find('div[id="new-field-lot"]').text()
        url = 'http://bankruptcy.lot-online.ru/e-auction/' + $(@).find('a.filed.filed-title').attr('href')
        amqp.publish.sync null, config.tradeUrlsQueue, '', headers:
          url: url
          number: number
          etp: etp
          downloader: 'request'
          parser: 'lot-online/trade'
          queue: config.tradeHtmlQueue
      page += 1
      redis.set.sync null, etp.href, page.toString()
      if $('td[class="ui-datagrid-column"]').length is 0 then break
      form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&formMain%3Aj_idt85=22&formMain%3Aj_idt90=&formMain%3Aj_idt94=&formMain%3AitKeyWords=&formMain%3Aj_idt100=&formMain%3AauctionDatePlanBID_input=&formMain%3AauctionDatePlanEID_input=&formMain%3AcostBValueB=0&formMain%3AcostBValueE=0&formMain%3Aj_idt111=&formMain%3AselectIndPublish=3&javax.faces.ViewState=#{vstate}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clNext&javax.faces.partial.execute=formMain:clNext&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID&formMain:clNext=formMain:clNext"
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1