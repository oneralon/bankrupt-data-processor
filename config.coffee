module.exports =
  amqpUrl:          'amqp://localhost'
  listsQueue:       'bankrot-parser.lists'
  listHtmlWorkers:  2
  aucUrlQueue:      'bankrot-parser.aucUrl'
  aucHtmlQueue:     'bankrot-parser.aucHtml'
  lotUrlQueue:      'bankrot-parser.lotUrl'
  lotHtmlQueue:     'bankrot-parser.lotHtml'
  aucUrlWorkers:    32
  aucHtmlWorkers:   2
  lotUrlWorkers:    32
  lotHtmlWorkers:   2
  tmpDB:            'test-bankrot-parser-tmp'
  db:               'test-bankrot-parser'
  getPageTries:     10
  getPageTimeout:   30000
  timeout:          30000

  urls:
    'http://opentp.ru':                 'Открытая торговая площадка'
    # 'http://uralbidin.ru':              'ЭТП "UralBidIn"'
    # 'http://etp1.ru':                   'ЭТП №1'
    # 'http://etp-bankrotstvo.ru':        'ЭТП по продаже имущества банкротов'
    # 'https://gloriaservice.ru':         'ЭТП "Регион"'
    # 'http://meta-invest.ru':            'Мета-Инвест'
    # 'http://tendergarant.com':          'Тендер Гарант'
    # 'http://alfalot.ru':                'Альфалот'
    # 'http://bepspb.ru':                 'Балтийская ЭТП'
    # 'http://bankrupt.etp-agenda.ru':    'ЭТП "Агенда"'
    # 'http://bankrupt.centerr.ru':       'Центр реализации'
    # 'http://bankrupt.electro-torgi.ru': 'ЭТП по реализации имущества должников'
    # 'http://propertytrade.ru':          'Площадка Property Trade'
    # 'http://tenderstandart.ru':         'ТендерСтандарт'
    # 'http://utender.ru':                'uTender'
    # 'http://vertrades.ru/bankrupt':     'ВердиктЪ'
    # 'http://torgibankrot.ru':           'Южная ЭТП'
    # 'http://bankrupt.etpu.ru':          'Уральская ЭТП'
    # 'http://utpl.ru':                   'Объединенная торговая площадка'                     
    # 'http://ipsetp.ru':                 'АйПиЭс ЭТП'
    # 'http://etp.kartoteka.ru':          'Комерсантъ Картотека'
    # 'http://mts-etp.ru/':               'Межрегиональная торговая система'
    # 'http://bg-tender.ru/':             'ЭТП Бизнесс-Групп'