xml2js    = require 'xml2js'
_         = require 'lodash'
moment    = require 'moment'
Promise   = require 'promise'
Sync      = require 'sync'

xmlParser = new xml2js.Parser
  explicitArray: no

request   = require '../../downloaders/request-sber'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/

module.exports = (xml, etp, url, ismicro, cb) ->
  Sync =>
    try
      result = {}
      data = xmlParser.parseString.sync xmlParser, xml
      result.number = data.Purchase.PurchaseInfo.PurchaseCode
      result.type = data.Purchase.PurchaseTypeInfo.PurchaseTypeName
      types = data.Purchase.PurchaseTypeInfo.PurchaseTypeName.split ' с '
      result.trade_type = /(аукцион|конкурс|публичное предложение)/.exec(data.Purchase.PurchaseTypeInfo.PurchaseTypeName)[1]
      result.membership_type = if types[0].indexOf('Открыт') isnt -1 then 'открытая' else 'закрытая'
      result.price_submission_type = if types[1].indexOf('открыт') isnt -1 then 'открытая' else 'закрытая'
      result.title = data.Purchase.PurchaseInfo.PurchaseName
      result.additional = ""
      if data.Purchase.PurchaseInfo.IsPledge is 'Yes'
        result.additional += 'Имущество является предметом залога. '
      if data.Purchase.PurchaseInfo.RePurchase is 'Yes'
        result.additional += 'Повторные торги'
      if data.Purchase.ResultInfo?.ResultCriteria?
        result.win_procedure = data.Purchase.ResultInfo?.ResultCriteria
      result.submission_procedure = data.Purchase.RequestInfo.RegistrationDocuments
      if data.Purchase.ResultInfo?.AuctionResultDate?
        result.holding_date = moment(data.Purchase.ResultInfo.AuctionResultDate, 'DD.MM.YYYY HH:mm').format()
      else
        if data.Purchase.Terms?.PurchaseAuctionStartDate?
          result.holding_date = moment(data.Purchase.Terms.PurchaseAuctionStartDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase.RequestInfo?.RequestStartDate?
        result.requests_start_date = moment(data.Purchase.RequestInfo.RequestStartDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase.RequestInfo?.RequestStopDate?
        result.requests_end_date = moment(data.Purchase.RequestInfo.RequestStopDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase.PurchaseInfo.EfrPublicDate.length is 10
        result.official_publish_date = moment(data.Purchase.PurchaseInfo.PaperPublicDate, 'DD.MM.YYYY').format()
      else
        result.official_publish_date = moment(data.Purchase.PurchaseInfo.PaperPublicDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase.PurchaseInfo.EfrPublicDate.length is 10
        result.bankrot_date = moment(data.Purchase.PurchaseInfo.EfrPublicDate, 'DD.MM.YYYY').format()
      else
        result.bankrot_date = moment(data.Purchase.PurchaseInfo.EfrPublicDate, 'DD.MM.YYYY HH:mm').format()
      if data.Purchase.ResultInfo?.ResultPlace?
        result.results_place = data.Purchase.ResultInfo.ResultPlace
      if data.Purchase.ResultInfo?.AuctionResultDate?
        result.results_date = moment(data.Purchase.ResultInfo.AuctionResultDate, 'DD.MM.YYYY HH:mm').format()

      result.documents = []
      if data.Purchase.ContractInfo?.contractdoc?.file
        if data.Purchase.ContractInfo.contractdoc.file.length
          files = data.Purchase.ContractInfo.contractdoc.file
        else
          files = [data.Purchase.ContractInfo.contractdoc.file]
        files.forEach (file) ->
          result.documents.push {
            url: "http://utp.sberbank-ast.ru/Bankruptcy/File/DownloadFile?fid=#{file.fileid}"
            name: file.filename
          }

      if data.Purchase.DepositInfo?.DepositContractDoc?.file
        if data.Purchase.DepositInfo?.DepositContractDoc.file.length
          files = data.Purchase.DepositInfo?.DepositContractDoc.file
        else
          files = [data.Purchase.DepositInfo?.DepositContractDoc.file]
        files.forEach (file) ->
          result.documents.push {
            url: "http://utp.sberbank-ast.ru/Bankruptcy/File/DownloadFile?fid=#{file.fileid}"
            name: file.filename
          }

      result.debtor = {}
      result.debtor.debtor_type = if data.Purchase.DebtorInfo.PersonPhis is 'Yes' then 'Физическое лицо' else 'Юридическое лицо'
      result.debtor.inn = data.Purchase.DebtorInfo.DebtorINN
      result.debtor.full_name = data.Purchase.DebtorInfo.DebtorName
      result.debtor.ogrn = data.Purchase.DebtorInfo.DebtorOGRN
      result.debtor.judgment = data.Purchase.BusinesInfo.businessreason
      result.debtor.arbitral_name = data.Purchase.BusinesInfo.businessname
      result.debtor.bankruptcy_number = data.Purchase.BusinesInfo.businessno
      result.debtor.arbitral_commissioner = data.Purchase.CrisicManagerInfo.crisicmanagerfullname
      result.debtor.arbitral_organization = data.Purchase.CrisicManagerInfo.arbitrageorganizationpanel.arbitrageorganizationname
      result.debtor.contract_procedure = data.Purchase.ContractInfo.contractorder
      result.debtor.payment_terms = data.Purchase.ContractInfo.contractperiod

      result.owner = {}
      result.owner.full_name = data.Purchase.OrganizatorInfo.orgname
      result.owner.inn = data.Purchase.OrganizatorInfo.orginn

      result.owner.contact = {}
      result.owner.contact.phone = data.Purchase.OrganizatorInfo.orgphone
      result.owner.contact.internet_address = data.Purchase.OrganizatorInfo.orgemail

      console.log JSON.stringify result, null, 2
      
      e()
      cb null, trade
    catch e then cb(e)