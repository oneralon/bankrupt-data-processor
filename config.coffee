module.exports =
  amqpUrl:           'amqp://localhost'
  listsHtmlQueue:    'bankrupt-parser.listHtmls'
  tradeUrlsQueue:    'bankrupt-parser.tradeUrls'
  tradeHtmlQueue:    'bankrupt-parser.tradeHtml'
  tradeJsonQueue:    'bankrupt-parser.tradeJson'

  listWorkers:       1
  tradeUrlWorkers:   1
  tradeHtmlWorkers:  1
  timeout: 600000

  tmpDB:             'tmp-bankrupt-parser'
  prodDB:            'bankrot-parser'

  etps: [
    name: 'Открытая торговая площадка' #77
    href: 'http://opentp.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Регион"' #112
    href: 'https://www.gloriaservice.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "UralBidIn"' #307
    href: 'http://www.uralbidin.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Property Trade"' #692
    href: 'http://propertytrade.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Агенда"' #1244
    href: 'http://bankrupt.etp-agenda.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Мета-Инвест"' #1288
    href: 'http://meta-invest.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Уральская ЭТП' #1430
    href: 'http://bankrupt.etpu.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "ТендерСтандарт"' #2176
    href: 'http://tenderstandart.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Electro-Torgi"' #2191
    href: 'http://bankrupt.electro-torgi.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Арбитат"' #2455
    href: 'http://arbitat.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Южная ЭТП' #4004
    href: 'http://torgibankrot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Балтийская ЭТП' #4099
    href: 'http://www.bepspb.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Альфалот"' #4469
    href: 'http://alfalot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Объединенная торговая площадка' #5524
    href: 'http://www.utpl.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Вердиктъ"' #5446
    href: 'http://www.vertrades.ru/bankrupt/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Комерсантъ Картотека"' #11461
    href: 'http://etp.kartoteka.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка Центра реализации' #94395
    href: 'http://www.bankrupt.centerr.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "uTender"' #136013
    href: 'http://www.utender.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка №1' #0
    href: 'http://etp1.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "ТЕНДЕР ГАРАНТ"' #??? < 300
    href: 'http://tendergarant.com/public/purchases-all/'
    platform: 'i-tender'
  ]
