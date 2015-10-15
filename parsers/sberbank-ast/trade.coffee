xml2js    = require 'xml2js'
_         = require 'lodash'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'

xmlParser = new xml2js.Parser
  explicitArray: no

lotParser = require './lot'
request   = require '../../downloaders/request-sber'
logger    = require '../../helpers/logger'
log       = logger  'SBERBANK-AST TRADE PARSER'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

module.exports = (xml, etp, url, ismicro, cb) ->
  Sync =>
    try
      trade = {}
      data = xmlParser.parseString.sync xmlParser, xml
      trade.number = data.Purchase?.PurchaseInfo?.PurchaseCode
      trade.type = data.Purchase?.PurchaseTypeInfo?.PurchaseTypeName
      types = data.Purchase?.PurchaseTypeInfo?.PurchaseTypeName.split ' с '
      trade.trade_type = /(аукцион|конкурс|публичное предложение)/.exec(data.Purchase?.PurchaseTypeInfo?.PurchaseTypeName)[1]
      trade.membership_type = if types[0]?.indexOf('Открыт') isnt -1 then 'открытая' else 'закрытая'
      trade.price_submission_type = if types[1]?.indexOf('открыт') isnt -1 then 'открытая' else 'закрытая'
      trade.title = data.Purchase?.PurchaseInfo?.PurchaseName
      trade.additional = ""
      if data.Purchase?.PurchaseInfo?.IsPledge is 'Yes'
        trade.additional += 'Имущество является предметом залога. '
      if data.Purchase?.PurchaseInfo?.RePurchase is 'Yes'
        trade.additional += 'Повторные торги'
      if data.Purchase?.tradeInfo?.tradeCriteria?
        trade.win_procedure = data.Purchase?.tradeInfo?.tradeCriteria
      trade.submission_procedure = data.Purchase?.RequestInfo?.RegistrationDocuments
      if data.Purchase?.tradeInfo?.AuctiontradeDate?
        trade.holding_date = moment(data.Purchase?.tradeInfo.AuctiontradeDate, 'DD.MM.YYYY HH:mm').format()
      else
        if data.Purchase?.Terms?.PurchaseAuctionStartDate?
          trade.holding_date = moment(data.Purchase?.Terms.PurchaseAuctionStartDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase?.RequestInfo?.RequestStartDate?
        trade.requests_start_date = moment(data.Purchase?.RequestInfo?.RequestStartDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase?.RequestInfo?.RequestStopDate?
        trade.requests_end_date = moment(data.Purchase?.RequestInfo?.RequestStopDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase?.PurchaseInfo?.EfrPublicDate?.length is 10
        trade.official_publish_date = moment(data.Purchase?.PurchaseInfo?.PaperPublicDate, 'DD.MM.YYYY').format()
      else
        trade.official_publish_date = moment(data.Purchase?.PurchaseInfo?.PaperPublicDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase?.PurchaseInfo?.EfrPublicDate?.length is 10
        trade.bankrot_date = moment(data.Purchase?.PurchaseInfo?.EfrPublicDate, 'DD.MM.YYYY').format()
      else
        trade.bankrot_date = moment(data.Purchase?.PurchaseInfo?.EfrPublicDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase?.tradeInfo?.tradePlace?
        trade.trades_place = data.Purchase?.tradeInfo.tradePlace
      if data.Purchase?.tradeInfo?.AuctiontradeDate?
        trade.trades_date = moment(data.Purchase?.tradeInfo.AuctiontradeDate, 'DD.MM.YYYY HH:mm').format()

      trade.documents = []
      if data.Purchase?.ContractInfo?.contractdoc?.file
        if data.Purchase?.ContractInfo?.contractdoc.file.length
          files = data.Purchase?.ContractInfo?.contractdoc.file
        else
          files = [data.Purchase?.ContractInfo?.contractdoc.file]
        files.forEach (file) ->
          trade.documents.push {
            url: "http://utp.sberbank-ast.ru/Bankruptcy/File/DownloadFile?fid=#{file.fileid}"
            name: file.filename
          }

      if data.Purchase?.DepositInfo?.DepositContractDoc?.file
        if data.Purchase?.DepositInfo?.DepositContractDoc.file.length
          files = data.Purchase?.DepositInfo?.DepositContractDoc.file
        else
          files = [data.Purchase?.DepositInfo?.DepositContractDoc.file]
        files.forEach (file) ->
          trade.documents.push {
            url: "http://utp.sberbank-ast.ru/Bankruptcy/File/DownloadFile?fid=#{file.fileid}"
            name: file.filename
          }

      trade.debtor = {}
      trade.debtor.debtor_type = if data.Purchase?.DebtorInfo?.PersonPhis is 'Yes' then 'Физическое лицо' else 'Юридическое лицо'
      trade.debtor.inn = data.Purchase?.DebtorInfo?.DebtorINN
      trade.debtor.full_name = data.Purchase?.DebtorInfo?.DebtorName
      trade.debtor.ogrn = data.Purchase?.DebtorInfo?.DebtorOGRN
      trade.debtor.judgment = data.Purchase?.BusinesInfo?.businessreason
      trade.debtor.arbitral_name = data.Purchase?.BusinesInfo?.businessname
      trade.debtor.bankruptcy_number = data.Purchase?.BusinesInfo?.businessno
      trade.debtor.arbitral_commissioner = data.Purchase?.CrisicManagerInfo?.crisicmanagerfullname
      trade.debtor.arbitral_organization = data.Purchase?.CrisicManagerInfo?.arbitrageorganizationpanel.arbitrageorganizationname
      trade.debtor.contract_procedure = data.Purchase?.ContractInfo?.contractorder
      trade.debtor.payment_terms = data.Purchase?.ContractInfo?.contractperiod

      trade.owner = {}
      trade.owner.full_name = data.Purchase?.OrganizatorInfo?.orgname
      trade.owner.inn = data.Purchase?.OrganizatorInfo?.orginn

      trade.owner.contact = {}
      trade.owner.contact.phone = data.Purchase?.OrganizatorInfo?.orgphone
      trade.owner.contact.internet_address = data.Purchase?.OrganizatorInfo?.orgemail

      trade.lots = []
      if _.isArray(data.Purchase?.Bids.Bid)
        bids = data.Purchase?.Bids.Bid
      else
        bids = [data.Purchase?.Bids.Bid]
      bids.forEach (bid)->
        url = "http://utp.sberbank-ast.ru/Bankruptcy/NBT/BidView/#{data.Purchase.PurchaseTypeInfo.PurchaseTypeId}/0/0/#{bid.BidId}"
        xml = request.sync null, url
        log.info "Loaded #{url}"
        lot = lotParser.sync null, xml, data, etp
        lot.url = url
        lot.current_sum = bid.CurrentPrice or bid.BidCurrentPrice or bid.BidPrice
        lot.discount = lot.start_price - lot.current_sum
        lot.discount_percent = lot.discount / lot.start_price
        lot.deposit_size = bid.BidCurrentDeposit or bid.BidDeposit
        lot.intervals = lot.intervals or []
        unless lot.intervals.length is 0
          lot.intervals.forEach (item, index) ->
            item.price_reduction_percent = data.Purchase?.PeriodReducePrice?.Periods[index]?.ReducePriceInPercent
        else
          if data.Purchase?.PeriodReducePrice?.Periods?
            if data.Purchase?.PeriodReducePrice?.Periods?.length
              periods = data.Purchase?.PeriodReducePrice?.Periods
            else
              periods = [data.Purchase?.PeriodReducePrice?.Periods]
            unless _.isEmpty periods
              lot.intervals = periods.map (item) ->
                {
                  interval_start_date: moment(item.PeriodStartDate, 'DD.MM.YYYY HH.mm').format()
                  interval_end_date: moment(item.PeriodStopDate, 'DD.MM.YYYY HH.mm').format()
                  price_reduction_percent: Number(item.ReducePriceInPercent.trim().replace(/\s/g, '').replace(/,/g, '.').trim())
                }
        trade.lots.push lot
      cb null, trade
    catch e then cb(e)