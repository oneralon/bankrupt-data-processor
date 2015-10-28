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
  # proxy: 'http://127.0.0.1:18118'
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

emptyForm =
  'formMain': 'formMain'
  'formMain:commonSearchCriteriaStr': null
  # 'javax.faces.ViewState':null
  'formMain:msgBoxText': null
  'javax.faces.partial.ajax': false
  # 'javax.faces.source': 'formMain:j_idt163:6:clPage'
  # 'javax.faces.partial.execute': 'formMain:j_idt163:6:clPage'
  # 'formMain:j_idt163:6:clPage': 'formMain:j_idt163:6:clPage'
  'javax.faces.partial.render': 'formMain:panelList formMain:LotListPaginatorID'

Sync =>
  try
    log.info "Start collecting #{etp.name}"
    page = parseInt redis.get.sync(null, etp.href) or '0'
    html = needle.get.sync null, 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml', options
    $ = cheerio.load html[1]
    cookie = html[0].headers['set-cookie'][0].match(/^(JSESSIONID=[a-zA-Z0-9.]+);/)[1]
    vstate = $('input[id="javax.faces.ViewState"]').val()
    form = emptyForm
    param = "formMain:j_idt163:clPage50"
    form['javax.faces.source'] = form['javax.faces.partial.execute'] = form[param] = param
    # form['javax.faces.ViewState'] = vstate
    while true
      options.cookie = cookie
      log.info form['javax.faces.source']
      html = needle.post.sync null, etp.href, form, options
      $ = cheerio.load html[1]
      vstate = $('input[id="javax.faces.ViewState"]').val()
      form = emptyForm
      param = "formMain:j_idt163:#{page}:clPage50"
      form['javax.faces.source'] = form['javax.faces.partial.execute'] = form[param] = param
      # form['javax.faces.ViewState'] = vstate
      console.log $('#new-field-lot').text()
      page += 1
      redis.set.sync null, etp.href, page.toString()
    log.info "Complete collecting #{etp.name}"
    process.exit 0
  catch e
    log.error e
    process.exit 1