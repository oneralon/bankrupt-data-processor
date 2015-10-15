needle    = require 'needle'
cheerio   = require 'cheerio'
xml2js    = require 'xml2js'
Sync      = require 'sync'

xmlParser = new xml2js.Parser
  explicitArray: no

options =
  proxy: 'http://127.0.0.1:18118'
  compressed: true
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.132 Safari/537.36'
  follow_max: 10
  follow_set_cookies: true
  follow_set_referer: true

module.exports = (trade, lot, cb) ->
  price = Math.round(lot.start_price)
  form =
    xmlFilter: "<query><purchcode>#{trade}</purchcode><purchname>#{lot.title}</purchname><typeid></typeid><typename></typename><bidstatusid></bidstatusid><haspicture></haspicture><repurchase></repurchase><ispledge></ispledge><amountstart>#{price - 1}</amountstart><amountend>#{price + 1}</amountend><currentamountstart></currentamountstart><currentamountend></currentamountend><orgid></orgid><orgname></orgname><debtorinn></debtorinn><debtorname></debtorname><requeststartdatestart></requeststartdatestart><requeststartdateend></requeststartdateend><requestdatestart></requestdatestart><requestdateend></requestdateend><auctionstartdatestart></auctionstartdatestart><auctionstartdateend></auctionstartdateend><purchdescription></purchdescription><regionid></regionid><regionname></regionname><purchasegroupid></purchasegroupid><purchasegroupname></purchasegroupname></query>"
    hdnPageNum: 1
    RequestStartDateStart: null
    RequestStartDateEnd: null
    requestDateStart: null
    requestDateEnd: null
    auctionStartDateStart: null
    auctionStartDateEnd: null

  Sync =>
    try
      while typeof data is 'undefined' or not data? or data is ''
        data = get.sync null, form, lot.number
      cb null, data
    catch e then cb e

get = (form, number, cb) ->
  needle.post 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList', form, options, (err, resp, body) ->
    cb() if err? or not body?
    if typeof body isnt 'undefined'
      $ = cheerio.load body
      xml = $('#xmlData').val()
      if xml? and xml.length > 0 and xml isnt "<List />" and xml[0] is '<'
        json = xmlParser.parseString.sync xmlParser, xml
        if json.List.data.row.length > 0
          row = json.List.data.row.filter( (i) ->
            i.BidNo.toString() is number.toString()
          )[0]
          if row? then cb null, row.PurchaseState else cb()
        else
          cb null, json.List.data.row.PurchaseState
      else cb()
    else cb()