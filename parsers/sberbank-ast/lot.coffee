_         = require 'lodash'
moment    = require 'moment'
xml2js    = require 'xml2js'
Sync      = require 'sync'
logger    = require '../../helpers/logger'
log       = logger  'SBERBANK-AST LOT PARSER'
config    = require '../../config'
lot_status = require './lot-status'

host      = /^https?\:\/\/[A-Za-z0-9\.\-]+/
xmlParser = new xml2js.Parser
  explicitArray: no

module.exports = (xml, trade, etp, cb) ->
  Sync =>
    try
      lot = {}
      data = xmlParser.parseString.sync xmlParser, xml

      lot.number = Number data.BidView.Bids.BidInfo.BidNo
      lot.title = data.BidView.Bids.BidInfo.BidName.trim()
      lot.region = data.BidView.Bids.BidDebtorInfo.BidRegion
      lot.status = data.BidView.BidChangeLog.BidChangeLogString[0].BidChangeLogComment
      lot.procedure = trade.Purchase.RequestInfo.RegistrationDocuments
      if data.BidView.Bids.BidDebtorInfo?.BidCategoryInfo?.bidcategorys?
        if data.BidView.Bids.BidDebtorInfo?.BidCategoryInfo?.bidcategorys?.length
          lot.category = (data.BidView.Bids.BidDebtorInfo.BidCategoryInfo.bidcategorys.map (item) -> item.bidcategoryname).join ' '
        else
          lot.category = data.BidView.Bids.BidDebtorInfo.BidCategoryInfo.bidcategorys.bidcategoryname
      else
        lot.category = ''
      lot.information = data.BidView.Bids.BidDebtorInfo.DebtorBidName
      lot.tags = []
      lot.information = lot.information + ' . Порядок ознакомления с имуществом (предприятием) должника: ' + data.BidView.Bids.BidDebtorInfo.BidInventoryResearchType
      lot.start_price = data.BidView.Bids.BidTenderInfo.BidPrice
      if data.BidView.Bids.BidTenderInfo?.BidAuctionStepPercent?
        lot.step_percent = data.BidView.Bids.BidTenderInfo.BidAuctionStepPercent
      if data.BidView.Bids.BidDepositInfo?.BidDepositRefund?
        lot.deposit_procedure = data.BidView.Bids.BidDepositInfo.BidDepositRefund
      if data.BidView.Bids.BidInfo.BidTenderInfo?.BidAuctionStepPercent?
        lot.step_percent = data.BidView.Bids.BidInfo.BidTenderInfo.BidAuctionStepPercent
      if data.BidView.Bids.BidInfo.BidTenderInfo?.BidPrice?
        lot.start_price = data.BidView.Bids.BidInfo.BidTenderInfo?.BidPrice

      if data.BidView.BidReductionPeriod?.Periods?
        if data.BidView.BidReductionPeriod?.Periods?.length
          data = data.BidView.BidReductionPeriod?.Periods
        else
          data = [data.BidView.BidReductionPeriod?.Periods]
        lot.intervals = data.map (item) ->
          {
            interval_start_date: moment(item.PeriodStartDate, 'DD.MM.YYYY HH:mm').format()
            interval_end_date: moment(item.PeriodEndDate, 'DD.MM.YYYY HH:mm').format()
            deposit_sum: Number(item.ReservationCoverAmount.trim().replace(/\s/g, '').replace(/,/g, '.').trim())
            interval_price: Number(item.BidAmount.trim().replace(/\s/g, '').replace(/,/g, '.').trim())
          }
      lot.status = lot_status.sync, null trade.number, lot.title
      cb null, lot
    catch e then cb(e)