phantom   = require 'node-phantom-simple'
Sync      = require 'sync'

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
        result = @proceed.sync @, @current
        while result > 1
          @current += 1
          result = @proceed.sync @, @current
        @close.sync @
        log.info "Complete collecting #{@etp.url}"
        cb()
      catch e then @close -> cb e

  proceed: (number, cb) ->
    loaded = false
    saved = false
    @page.onResourceReceived = (response) =>
      if not loaded and response.url is 'http://utp.sberbank-ast.ru/Bankruptcy/List/BidList'
        loaded = true
        @page.evaluate """function(){$('#tbl > tbody').bind('DOMSubtreeModified',function(){console.log('UPDATED_NEW_DATA')});}"""
    @page.onConsoleMessage = (message) =>
      if not saved and message is 'UPDATED_NEW_DATA'
        saved = true
        Sync =>
          try
            html = @page.get.sync null, 'content'
            amqp.publish.sync null, config.listsHtmlQueue, new Buffer(html, 'utf8'),
              headers:
                parser: 'sberbank-ast/list'
                etp: @etp
            rows = @page.evaluate.sync null, 'function(){return $("#tbl > tbody > tr").length;}'
            log.info "Complete page #{@current} of #{@etp.url} with #{rows} rows"
            redis.set.sync null, @etp.url, @current
            cb(null, rows)
          catch e then @close -> cb e
    @page.evaluate "function(){pageChange(#{@current});}"

argv = require('optimist').argv
etp = {name: argv.name, url: argv.url, platform: argv.platform}
collector.collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0