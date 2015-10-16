module.exports =
  amqpUrl:           'amqp://localhost'
  listsHtmlQueue:    'bankrupt-parser.listHtmls'
  tradeUrlsQueue:    'bankrupt-parser.tradeUrls'
  tradeHtmlQueue:    'bankrupt-parser.tradeHtml'
  tradeJsonQueue:    'bankrupt-parser.tradeJson'

  listWorkers:       2
  tradeUrlWorkers:   16
  tradeHtmlWorkers:  64
  tradeJsonWorkers:  2
  timeout:           60000
  incUpdTime:        30000

  database:          'bankrot-parser'

  etps: [
  #   name: 'ЭТП "Аукционы Сибири"'
  #   href: 'http://ausib.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "Аукционный тендерный центр"'
  #   href: 'http://www.atctrade.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "ВТБ Центр"'
  #   href: 'http://vtb-center.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "Новые Информаионные Сервисы"'
  #   href: 'http://nistp.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "AukcionCenter"'
  #   href: 'http://www.aukcioncenter.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "Система Электронных Торгов Имуществом"'
  #   href: 'http://www.seltim.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "Профит"'
  #   href: 'http://www.etp-profit.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "RegTorg"'
  #   href: 'http://www.regtorg.com/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "А-КОСТА"'
  #   href: 'http://www.akosta.info/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "Поволжский Аукционный Дом"'
  #   href: 'http://bankrot.auction63.ru/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "ВЭТП"'
  #   href: 'http://xn-----6kcbaifbn4di5abenic8aq7kvd6a.xn--p1ai/etp/trade/list.html'
  #   platform: 'u-trade'
  # ,
  #   name: 'ЭТП "EkSystems"'
  #   href: 'http://www.eksystems.ru/etp/trade/list.html?type=bankruptcySales'
  #   platform: 'u-trade'
  # ,
    name: 'Открытая торговая площадка'
    href: 'http://opentp.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Регион"'
    href: 'https://www.gloriaservice.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "UralBidIn"'
    href: 'http://www.uralbidin.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Property Trade"'
    href: 'http://propertytrade.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Агенда"'
    href: 'http://bankrupt.etp-agenda.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Мета-Инвест"'
    href: 'http://meta-invest.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Уральская ЭТП'
    href: 'http://bankrupt.etpu.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "ТендерСтандарт"'
    href: 'http://tenderstandart.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Electro-Torgi"'
    href: 'http://bankrupt.electro-torgi.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Арбитат"'
    href: 'http://arbitat.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Южная ЭТП'
    href: 'http://torgibankrot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Балтийская ЭТП'
    href: 'http://www.bepspb.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Альфалот"'
    href: 'http://alfalot.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Объединенная торговая площадка'
    href: 'http://www.utpl.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Вердиктъ"'
    href: 'http://www.vertrades.ru/bankrupt/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "Комерсантъ Картотека"'
    href: 'http://etp.kartoteka.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка Центра реализации'
    href: 'http://www.bankrupt.centerr.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "uTender"'
    href: 'http://www.utender.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'Электронная площадка №1'
    href: 'http://etp1.ru/public/purchases-all/'
    platform: 'i-tender'
  ,
    name: 'ЭТП "ТЕНДЕР ГАРАНТ"'
    href: 'http://tendergarant.com/public/purchases-all/'
    platform: 'i-tender'
  ]
