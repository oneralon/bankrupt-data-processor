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
  tmpDB:            'bankrot-parser-tmp'
  db:               'bankrot-parser'
  timeout:          30000

  urls:
    'http://www.opentp.ru':             'Открытая торговая площадка'
    'http://www.uralbidin.ru':          'ЭТП "UralBidIn"'
    'http://www.etp1.ru':               'ЭТП №1'
    'http://www.etp-bankrotstvo.ru':    'ЭТП по продаже имущества банкротов'
    'https://www.gloriaservice.ru':     'ЭТП "Регион"'
    'http://www.meta-invest.ru':        'Мета-Инвест'
    'http://www.tendergarant.com':      'Тендер Гарант'
    'http://www.alfalot.ru':            'Альфалот'
    'http://bepspb.ru':                 'Балтийская ЭТП'
    'http://bankrupt.etp-agenda.ru':    'ЭТП "Агенда"'
    'http://bankrupt.centerr.ru':       'Центр реализации'
    'http://bankrupt.electro-torgi.ru': 'Площадка electro-torgi'
    'http://www.propertytrade.ru':      'Площадка Property Trade'
    'http://tenderstandart.ru':         'ТендерСтандарт'
    'http://utender.ru':                'uTender'
    'http://www.vertrades.ru/bankrupt': 'ВердиктЪ'
    'http://torgibankrot.ru':           'Южная ЭТП'
    'http://bankrupt.etpu.ru':          'Уральская ЭТП'
    'http://www.utpl.ru':               'Объединенная торговая площадка'                     
    'http://ipsetp.ru':                 'АйПиЭс ЭТП'