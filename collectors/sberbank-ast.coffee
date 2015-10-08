needle    = require 'needle'
Sync      = require 'sync'
cheerio   = require 'cheerio'
xml2js    = require 'xml2js'
amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
log       = logger  'SBERBANK-AST LIST COLLECTOR'
config    = require '../config'

xmlParser = new xml2js.Parser
  explicitArray: no

options =
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true

form =
  xmlFilter: '<query><purchcode></purchcode><purchname></purchname><typeid></typeid><typename></typename><bidstatusid></bidstatusid><haspicture></haspicture><repurchase></repurchase><ispledge></ispledge><amountstart>0</amountstart><amountend>1000000000000</amountend><currentamountstart></currentamountstart><currentamountend></currentamountend><orgid></orgid><orgname></orgname><debtorinn></debtorinn><debtorname></debtorname><requeststartdatestart></requeststartdatestart><requeststartdateend></requeststartdateend><requestdatestart></requestdatestart><requestdateend></requestdateend><auctionstartdatestart></auctionstartdatestart><auctionstartdateend></auctionstartdateend><purchdescription></purchdescription><regionid></regionid><regionname></regionname><purchasegroupid></purchasegroupid><purchasegroupname></purchasegroupname></query>'
  hdnPageNum: 1
  RequestStartDateStart: null
  RequestStartDateEnd: null
  requestDateStart: null
  requestDateEnd: null
  auctionStartDateStart: null
  auctionStartDateEnd: null

argv = require('optimist').argv
etp = {name: argv.name, url: argv.href, platform: argv.platform}


collect = (etp, cb) ->
  Sync =>
    try
      current = parseInt(redis.get.sync null, etp.url) or 1085
      result = proceed.sync null, current, etp
      while result isnt null
        current += 1
        result = proceed.sync null, current, etp
      log.info "Complete collecting #{etp.url}"
      cb()
    catch e then cb e

proceed = (number, etp, cb) ->
  Sync =>
    try
      form.hdnPageNum = number
      resp = needle.post.sync null, 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList', form, options
      $ = cheerio.load resp[0]?.body or resp.body
      xml = $('#xmlData').val()
      if xml isnt "<List />"
        json = xmlParser.parseString.sync xmlParser, xml
        rows = json.List.data.row
        urls = []
        result = []
        rows.forEach (row) ->
          url = "http://utp.sberbank-ast.ru/Bankruptcy/NBT/PurchaseView/#{row.TypeId}/0/0/#{row.PurchaseId}"
          if urls.indexOf(url) is -1
            urls.push url
            result.push url: url, number: row.PurchaseCode
        amqp.publish.sync null, config.listsHtmlQueue, new Buffer(JSON.stringify(result), 'utf8'),
          headers:
            parser: 'sberbank-ast/list'
            etp: etp
        log.info "Complete page #{number} of #{etp.url} with #{rows.length} rows"
        redis.set.sync null, etp.url, number
        cb(null, rows)
      else cb()
    catch e then cb e

collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0