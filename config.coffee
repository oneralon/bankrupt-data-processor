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
  tradeUrlWorkers:   1
  tradeHtmlWorkers:  1
  tradeJsonWorkers:  1
  lotUrlWorkers:     8
  lotHtmlWorkers:    1
  lotJsonWorkers:    1
  timeout:           60000
  incUpdTime:        30000

  database:          'bankrot-parser'

  etps: [
    name: 'Российский аукционный дом'
    href: 'http://bankruptcy.lot-online.ru/e-auction/lots.xhtml'
    platform: 'lot-online'
    tor: no
    compressed: yes
  ,
    name: 'Cбербанк. Автоматизированная система торгов'
    href: 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList'
    platform: 'sberbank-ast'
    tor: yes
    compressed: yes
  ,
    name: 'ЭТП "Аукционы Дальнего Востока"'
    href: 'http://torgidv.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "МЭТС"'
    href: 'http://m-ets.ru/search?r_num=О&lots=&debtor=&org=&arb=&arb_org=&stat=&sort=&desc='
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Аукционы Сибири"'
    href: 'http://ausib.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Аукционный тендерный центр"'
    href: 'http://atctrade.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ВТБ Центр"'
    href: 'http://vtb-center.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Новые Информацонные Сервисы"'
    href: 'http://nistp.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Аукцион-центр"'
    href: 'http://aukcioncenter.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Система Электронных Торгов Имуществом"'
    href: 'http://seltim.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Профит"'
    href: 'http://etp-profit.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'Региональная торговая площадка'
    href: 'http://regtorg.com/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "А-КОСТА"'
    href: 'http://akosta.info/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Поволжский Аукционный Дом"'
    href: 'http://bankrot.auction63.ru/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'Всероссийская Электронная Торговая Площадка'
    href: 'http://xn-----6kcbaifbn4di5abenic8aq7kvd6a.xn--p1ai/etp/trade/list.html'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
    name: 'Электронный капитал'
    href: 'http://eksystems.ru/etp/trade/list.html?type=bankruptcySales'
    platform: 'u-trade'
    tor: yes
    compression: yes
  ,
  #---------------------------------------------------------------------------------
    name: 'ЭТП "Банкротство"'
    href: 'http://etp-bankrotstvo.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Открытая торговая площадка'
    href: 'http://opentp.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Регион"'
    href: 'https://gloriaservice.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: no
    compression: yes
  ,
    name: 'ЭТП "UralBidIn"'
    href: 'http://uralbidin.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Property Trade"'
    href: 'http://propertytrade.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Агенда"'
    href: 'http://bankrupt.etp-agenda.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Мета-Инвест"'
    href: 'http://meta-invest.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Уральская ЭТП'
    href: 'http://bankrupt.etpu.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ТендерСтандарт"'
    href: 'http://tenderstandart.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Electro-Torgi"'
    href: 'http://bankrupt.electro-torgi.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Арбитат"'
    href: 'http://arbitat.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Южная ЭТП'
    href: 'http://torgibankrot.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Балтийская ЭТП'
    href: 'http://bepspb.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "Альфалот"'
    href: 'http://alfalot.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Объединенная торговая площадка'
    href: 'http://utpl.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'ЭТП "Вердиктъ"'
    href: 'http://vertrades.ru/bankrupt/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "KARTOTEKA.RU"'
    href: 'http://etp.kartoteka.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'Электронная площадка Центра реализации'
    href: 'http://bankrupt.centerr.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'ЭТП "uTender"'
    href: 'http://utender.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compressed: yes
  ,
    name: 'Электронная площадка №1'
    href: 'http://etp1.ru/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ,
    name: 'ЭТП "ТЕНДЕР ГАРАНТ"'
    href: 'http://tendergarant.com/public/purchases-all/'
    platform: 'i-tender'
    tor: yes
    compression: yes
  ]

  getEtp: (url) ->
    r = new RegExp(url.match(/^https?\:\/\/(www\.)?([A-Za-z0-9\.\-]+)/)[2])
    return @etps.filter( (t) ->
      r.test t.href
    )?[0]
