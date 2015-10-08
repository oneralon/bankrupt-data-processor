phantom   = require 'node-phantom-simple'
Sync      = require 'sync'
xmlParser = require 'node-xml-lite'
amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
log       = logger  'SBERBANK-AST LIST COLLECTOR'
config    = require '../config'

collector =
  phantom: null
  page: null
  current: null
  etp: null
  init: (cb) ->
    Sync =>
      try
        @phantom = phantom.create.sync null
        @phantom.onError = (err) ->
          log.info err
          @close -> cb err
        @current = parseInt(redis.get.sync null, @etp.url) or 1
        @page = @phantom.createPage.sync null
        res = @page.open.sync @, @etp.url
        cb "Non 200 code page" unless res is 'success'
        log.info "Start collecting #{@etp.url}"
        cb()
      catch e then @close -> cb e

  close: (cb) ->
    @phantom.exit()
    cb()

  collect: (etp, cb) ->
    @etp = etp
    Sync =>
      try
        @init.sync @
        @watchdog = setInterval =>
          if @phantom.exitCode isnt null
            @close -> cb 'Killed phantom'
        , 120000
        result = @proceed.sync @, @current
        while result isnt null
          @current += 1
          result = @proceed.sync @, @current
        @close.sync @
        log.info "Complete collecting #{@etp.url}"
        cb()
      catch e then @close -> cb e

  proceed: (number, cb) ->
    loaded = false
    @page.evaluate "function(){pageChange(#{@current});}"
    @page.onResourceReceived = (response) =>
      if not loaded and response.url is 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList'
        loaded = true
        Sync =>
          try
            while not xml?
              xml = @page.evaluate.sync null, -> $('#xmlData').val()
            if xml isnt "<List />"
              json = xmlParser.parseString xml
              rows = json.childs[0].childs
              urls = []
              result = []
              rows.forEach (row) ->
                lot = {}
                for field in row.childs
                  lot[field.name] = field.childs[0]
                url = "http://utp.sberbank-ast.ru/Bankruptcy/NBT/PurchaseView/#{lot.TypeId}/0/0/#{lot.PurchaseId}"
                if urls.indexOf(url) is -1
                  urls.push url
                  result.push url: url, number: lot.PurchaseCode
              amqp.publish.sync null, config.listsHtmlQueue, new Buffer(JSON.stringify(result), 'utf8'),
                headers:
                  parser: 'sberbank-ast/list'
                  etp: @etp
              log.info "Complete page #{@current} of #{@etp.url} with #{rows.length} rows"
              redis.set.sync null, @etp.url, @current
              cb(null, rows)
            else cb()
          catch e then @close -> cb e

argv = require('optimist').argv
etp = {name: argv.name, url: argv.href, platform: argv.platform}
collector.collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0