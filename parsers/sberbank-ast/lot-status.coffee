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

module.exports = (trade, title, number, cb) ->
  form =
    xmlFilter: "<query><purchcode>#{trade}</purchcode><purchname>#{title}</purchname><typeid></typeid><typename></typename><bidstatusid></bidstatusid><haspicture></haspicture><repurchase></repurchase><ispledge></ispledge><amountstart>0</amountstart><amountend>1000000000000</amountend><currentamountstart></currentamountstart><currentamountend></currentamountend><orgid></orgid><orgname></orgname><debtorinn></debtorinn><debtorname></debtorname><requeststartdatestart></requeststartdatestart><requeststartdateend></requeststartdateend><requestdatestart></requestdatestart><requestdateend></requestdateend><auctionstartdatestart></auctionstartdatestart><auctionstartdateend></auctionstartdateend><purchdescription></purchdescription><regionid></regionid><regionname></regionname><purchasegroupid></purchasegroupid><purchasegroupname></purchasegroupname></query>"
    hdnPageNum: 1
    RequestStartDateStart: null
    RequestStartDateEnd: null
    requestDateStart: null
    requestDateEnd: null
    auctionStartDateStart: null
    auctionStartDateEnd: null

  Sync =>
    try
      resp = needle.post.sync null, 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList', form, options
      $ = cheerio.load resp['0'].body
      xml = $('#xmlData').val()
      if xml? and xml isnt "<List />"
        json = xmlParser.parseString.sync xmlParser, xml
        if json.List.data.row.length > 0
          row = json.List.data.row.filter( (i) ->
            i.BidNo.toString() is number.toString()
          )[0]
          cb null, row.PurchaseState
        else
          cb null, json.List.data.row.PurchaseState
      else cb("Empty list")
    catch e then cb(e)