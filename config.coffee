module.exports =
  amqpUrl:           'amqp://localhost'
  listsHtmlQueue:    'bankrupt-parser.listHtmls'
  tradeUrlsQueue:    'bankrupt-parser.tradeUrls'
  tradeHtmlQueue:    'bankrupt-parser.tradeHtml'
  lotsUrlsQueue:     'bankrupt-parser.lotsUrls'
  lotsHtmlQueue:     'bankrupt-parser.lotsHtml'

  listWorkers:       1
  lotUrlWorkers:     2
  tradeUrlWorkers:   4
  lotHtmlWorkers:    2
  tradeHtmlWorkers:  2
  timeout: 600000

  tmpDB:             'tmp-bankrupt-parser'
  prodDB:            'prod-bankrupt-parser'

  etps: [
    name: 'ЭТП uTender'
    url: 'http://www.utender.ru/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка Центра реализации'
    url: 'http://www.bankrupt.centerr.ru/'
    platform: 'i-tender'
  ,
    name: 'ЭТП Вердиктъ'
    url: 'http://www.vertrades.ru/bankrupt/'
    platform: 'i-tender'
  ,
    name: 'Объединенная торговая площадка'
    url: 'http://www.utpl.ru/'
    platform: 'i-tender'
  ,
    name: 'Балтийская ЭТП'
    url: 'http://www.bepspb.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Открытая торговая площадка'
    url: 'http://opentp.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Первая ЭТП'
    url: 'http://etp1.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Регион"'
    url: 'https://www.gloriaservice.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП UralBidIn'
    url: 'http://www.uralbidin.ru/public/purchases-all/'
    platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'
  # ,
  #   name: ''
  #   url: ''
  #   platform: 'i-tender'

  ]
