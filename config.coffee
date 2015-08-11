module.exports =
  amqpUrl:           'amqp://localhost'
  listsHtmlQueue:    'bankrupt-parser.listHtmls'
  tradeUrlsQueue:    'bankrupt-parser.tradeUrls'
  tradeHtmlQueue:    'bankrupt-parser.tradeHtml'
  lotsUrlsQueue:     'bankrupt-parser.lotsUrls'
  lotsHtmlQueue:     'bankrupt-parser.lotsHtml'

  listWorkers:       4
  lotUrlWorkers:     16
  tradeUrlWorkers:   16
  lotHtmlWorkers:    4
  tradeHtmlWorkers:  4
  timeout: 600000

  tmpDB:             'tmp-bankrupt-parser'
  prodDB:            'prod-bankrupt-parser'

  etps: [
    name: 'Открытая торговая площадка' #77
    url: 'http://opentp.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Регион"' #112
    url: 'https://www.gloriaservice.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "UralBidIn"' #307
    url: 'http://www.uralbidin.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Property Trade"' #692
    url: 'http://propertytrade.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Агенда"' #1244
    url: 'http://bankrupt.etp-agenda.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Мета-Инвест"' #1288
    url: 'http://meta-invest.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Уральская ЭТП' #1430
    url: 'http://bankrupt.etpu.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "ТендерСтандарт"' #2176
    url: 'http://tenderstandart.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Electro-Torgi"' #2191
    url: 'http://bankrupt.electro-torgi.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Арбитат"' #2455
    url: 'http://arbitat.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Южная ЭТП' #4004
    url: 'http://torgibankrot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Балтийская ЭТП' #4099
    url: 'http://www.bepspb.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Альфалот"' #4469
    url: 'http://alfalot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Объединенная торговая площадка' #5524
    url: 'http://www.utpl.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Вердиктъ"' #5446
    url: 'http://www.vertrades.ru/bankrupt/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка Центра реализации' #94395
    url: 'http://www.bankrupt.centerr.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "uTender"' #136013
    url: 'http://www.utender.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка №1' #0
    url: 'http://etp1.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: '«ТЕНДЕР ГАРАНТ»' #??? < 300
    url: 'http://tendergarant.com/public/purchases-all/'
    platform: 'i-tender'
  ]
