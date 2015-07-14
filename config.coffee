module.exports =
  amqpUrl:          'amqp://localhost'
  listsQueue:       'bankrot-parser.lists'
  listHtmlWorkers:  8
  aucUrlQueue:      'bankrot-parser.aucUrl'
  aucHtmlQueue:     'bankrot-parser.aucHtml'
  lotUrlQueue:      'bankrot-parser.lotUrl'
  lotHtmlQueue:     'bankrot-parser.lotHtml'
  aucUrlWorkers:    32
  aucHtmlWorkers:   8
  lotUrlWorkers:    32
  lotHtmlWorkers:   8
  tmpDB:            'bankrot-parser-tmp'
  db:               'bankrot-parser'
  timeout:          30000

  urls: [
    'http://www.opentp.ru'
    'http://www.uralbidin.ru'
    'https://www.gloriaservice.ru'
    'http://www.meta-invest.ru'
    'http://bepspb.ru'
    'http://www.tendergarant.com'
    'http://bankrupt.etp-agenda.ru'
    'http://bankrupt.electro-torgi.ru'
    'http://www.propertytrade.ru'
    'http://www.alfalot.ru'
    'http://www.arbitat.ru'
    'http://www.utpl.ru'
    'http://bankrupt.etpu.ru'
    'http://torgibankrot.ru'
    'http://www.vertrades.ru/bankrupt'
    'http://utender.ru'
    'http://tenderstandart.ru'
    'http://bankrupt.centerr.ru'
    'http://www.etp-bankrotstvo.ru'
    'http://www.etp1.ru'
    'http://ipsetp.ru'
  ]