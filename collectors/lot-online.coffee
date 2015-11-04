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
    'Faces-Request':'html'
    'Referer':'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml'

Sync =>
  try
    log.info "Start collecting #{etp.name}"
    page = parseInt redis.get.sync(null, etp.href) or '0'
    html = needle.get.sync null, 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml', options
    $ = cheerio.load html[1]
    options.cookies = 'JSESSIONID': html[0].headers['set-cookie'][0].match(/^JSESSIONID=([a-zA-Z0-9.]+);/)[1]
    form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{$('input[id="javax.faces.ViewState"]').val().replace(':','%3A')}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clNext&javax.faces.partial.execute=formMain:clNext&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID&formMain:clNext=formMain:clNext"
    while true
      html = needle.post.sync null, etp.href, form, options
      $ = cheerio.load html[1]
      form = "formMain=formMain&formMain%3AcommonSearchCriteriaStr=&javax.faces.ViewState=#{$('input[id="javax.faces.ViewState"]').val().replace(':','%3A')}&formMain%3AmsgBoxText=&javax.faces.partial.ajax=true&javax.faces.source=formMain:clNext&javax.faces.partial.execute=formMain:clNext&javax.faces.partial.render=formMain:panelList formMain:LotListPaginatorID&formMain:clNext=formMain:clNext"
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
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1