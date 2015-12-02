module.exports =
  amqpUrl:           'amqp://localhost'
  listsHtmlQueue:    'bankrupt-parser.listHtmls'
  tradeUrlsQueue:    'bankrupt-parser.tradeUrls'
  tradeHtmlQueue:    'bankrupt-parser.tradeHtml'
  tradeJsonQueue:    'bankrupt-parser.tradeJson'
  lotsUrlsQueue:     'bankrupt-parser.lotUrls'
  lotsHtmlQueue:     'bankrupt-parser.lotHtml'
  lotsJsonQueue:     'bankrupt-parser.lotJson'

  listWorkers:       1
  tradeUrlWorkers:   8
  tradeHtmlWorkers:  4
  tradeJsonWorkers:  1
  lotUrlWorkers:     8
  lotHtmlWorkers:    1
  lotJsonWorkers:    1
  timeout:           60000
  incUpdTime:        60000

  database:          'bankrot-parser'

  etps: [
    name: 'Межотраслевая торговая система "Фабрикант"'
    href: 'https://www.fabrikant.ru/trades/procedure/search/'
    url: 'fabrikant.ru'
    platform: 'fabrikant'
    tor: no
    compressed: yes
    timeout: 5 * 60 * 1000
  ,
    name: 'Российский аукционный дом'
    href: 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml'
    url: 'lot-online.ru'
    platform: 'lot-online'
    tor: no
    compressed: yes
    timeout: 10 * 60 * 1000
  ,
    name: 'ЗАО "Сбербанк-АСТ"'
    href: 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList'
    url: 'utp.sberbank-ast.ru/bankruptcy'
    platform: 'sberbank-ast'
    tor: yes
    compressed: yes
    timeout: 5 * 60 * 1000
  ,
    name: 'ЭТП "Пром-Консалтинг"'
    href: 'http://promkonsalt.ru/etp/trade/list.html'
    url: 'promkonsalt.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "МФБ"'
    href: 'http://etp.mse.ru/etp/trade/list.html'
    url: 'etp.mse.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Аукционы Дальнего Востока"'
    href: 'http://torgidv.ru/etp/trade/list.html'
    url: 'torgidv.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "МЭТС"'
    href: 'http://m-ets.ru/search'
    url: 'm-ets.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Аукционы Сибири"'
    href: 'http://ausib.ru/etp/trade/list.html'
    url: 'ausib.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Аукционный тендерный центр"'
    href: 'http://atctrade.ru/etp/trade/list.html'
    url: 'atctrade.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "ВТБ-Центр"'
    href: 'http://vtb-center.ru/etp/trade/list.html'
    url: 'vtb-center.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Новые Информацонные Сервисы"'
    href: 'http://nistp.ru/trades'
    url: 'nistp.ru'
    platform: 'u-trade'
    tor: no
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Аукцион-центр"'
    href: 'http://aukcioncenter.ru/etp/trade/list.html'
    url: 'aukcioncenter.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Система Электронных Торгов Имуществом"'
    href: 'http://seltim.ru/etp/trade/list.html'
    url: 'seltim.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Профит"'
    href: 'http://etp-profit.ru/etp/trade/list.html'
    url: 'etp-profit.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "А-КОСТА info"'
    href: 'http://akosta.info/etp/trade/list.html'
    url: 'akosta.info'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'ЭТП "Поволжский Аукционный Дом"'
    href: 'http://bankrot.auction63.ru/etp/trade/list.html'
    url: 'auction63.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'Всероссийская Электронная Торговая Площадка'
    href: 'http://xn-----6kcbaifbn4di5abenic8aq7kvd6a.xn--p1ai/etp/trade/list.html'
    url: 'торговая-площадка-вэтп.рф'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'Электронный капитал'
    href: 'http://eksystems.ru/etp/trade/list.html?type=bankruptcySales'
    url: 'eksystems.ru'
    platform: 'u-trade'
    tor: yes
    compression: yes
    timeout: -1
  ,
    name: 'Региональная торговая площадка'
    href: 'http://regtorg.com/etp/trade/list.html'
    url: 'regtorg.com'
    platform: 'u-trade'
    tor: no
    compression: yes
    timeout: -1
  ,
  #---------------------------------------------------------------------------------
    name: 'ЭТП "Банкротство"'
    href: 'http://etp-bankrotstvo.ru/public/purchases-all/'
    url: 'etp-bankrotstvo.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Открытая торговая площадка'
    href: 'http://opentp.ru/public/purchases-all/'
    url: 'opentp.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Регион"'
    href: 'https://gloriaservice.ru/public/purchases-all/'
    url: 'gloriaservice.ru'
    platform: 'i-tender'
    tor: no
    compression: yes
  ,
    name: 'ЭТП "UralBidIn"'
    href: 'http://uralbidin.ru/public/purchases-all/'
    url: 'uralbidin.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Property Trade"'
    href: 'http://propertytrade.ru/public/purchases-all/'
    url: 'propertytrade.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Агенда"'
    href: 'http://bankrupt.etp-agenda.ru/public/purchases-all/'
    url: 'etp-agenda.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Мета-Инвест"'
    href: 'http://meta-invest.ru/public/purchases-all/'
    url: 'meta-invest.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Уральская ЭТП'
    href: 'http://bankrupt.etpu.ru/public/purchases-all/'
    url: 'etpu.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ТендерСтандарт"'
    href: 'http://tenderstandart.ru/public/purchases-all/'
    url: 'tenderstandart.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ELECTRO-TORGI.RU"'
    href: 'http://bankrupt.electro-torgi.ru/public/purchases-all/'
    url: 'bankrupt.electro-torgi.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Арбитат"'
    href: 'http://arbitat.ru/public/purchases-all/'
    url: 'arbitat.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Южная ЭТП'
    href: 'http://torgibankrot.ru/public/purchases-all/'
    url: 'torgibankrot.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Балтийская ЭТП'
    href: 'http://bepspb.ru/public/purchases-all/'
    url: 'bepspb.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Альфалот"'
    href: 'http://alfalot.ru/public/purchases-all/'
    url: 'alfalot.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Объединенная торговая площадка'
    href: 'http://utpl.ru/public/purchases-all/'
    url: 'utpl.ru'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'ЭТП "Вердиктъ"'
    href: 'http://vertrades.ru/bankrupt/public/purchases-all/'
    url: 'vertrades.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "KARTOTEKA.RU"'
    href: 'http://etp.kartoteka.ru/public/purchases-all/'
    url: 'etp.kartoteka.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Электронная площадка Центра реализации'
    href: 'http://bankrupt.centerr.ru/public/purchases-all/'
    url: 'centerr.ru'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'ЭТП "uTender"'
    href: 'http://utender.ru/public/purchases-all/'
    url: 'utender.ru'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'Электронная площадка №1'
    href: 'http://etp1.ru/public/purchases-all/'
    url: 'etp1.ru'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ТЕНДЕР ГАРАНТ"'
    href: 'http://tendergarant.com/public/purchases-all/'
    url: 'tendergarant.com'
    platform: 'i-tender'
    tor: no
    compression: yes
  ]

  getEtp: (url) ->
    r = new RegExp(url.match(/^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/)[2])
    return @etps.filter( (t) ->
      r.test t.href
    )?[0]
