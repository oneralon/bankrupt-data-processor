phantom   = require 'node-phantom-simple'
amqp      = require 'amqplib'
Sync      = require 'sync'

logger    = require '../helpers/logger'
log       = logger  'I-TENDER LIST COLLECTOR'
config    = require '../config'

inject    = (to, from)->
  for key, val of from
    to[key] = val

module.exports =
  phantom: null
  current: null
  connection: null
  channel: null
  next: null
  url: null
  page: null
  interval: null
  cookies: null
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (channel) =>
        channel.assertQueue(config.listsHtmlQueue)
        Sync =>
          try
            ph = phantom.create.sync @
            page = ph.createPage.sync @
            cb null,
              connection: connection
              phantom: ph
              channel: channel
              page: page
          catch e
            log.error e
            cb e

  close: (cb) ->
    @page.close () =>
      @phantom.exit()
      @channel.close().catch(cb).then () =>
        @connection.close().catch(cb).then () =>
          cb()

  collect: (etp, cb) ->
    Sync =>
      try
        inject @, @init.sync(@)
        inject @, @proceed.sync @, etp
        @close.sync(@)
        log.info 'Collecting completed'
        cb()
      catch e
        log.error e
        cb e

  proceed: (etp, cb) ->
    log.info "Start collect #{etp.url}"
    @url = etp.url
    @etp = etp
    @current = 1
    @page.open @etp.url, (err, res) =>
      if err?
        log.error err
        cb e
      cb "Non 200 code page" unless res is 'success'
      Sync =>   
        try
          inject @, @nextPage.sync(@)
          while @next isnt null
            inject @, @nextPage.sync(@)
          log.info "Complete collect #{etp.url}"
          clearInterval @interval
          cb()
        catch e
          log.error e
          cb e

  nextPage: (cb) ->
    log.info "Start page #{@current} of #{@url}"
    @page.onConsoleMessage = (message) =>
      if message is 'UPDATED_NEW_DATA'
        log.info "Complete page #{@current} of #{@url}"
        cb(null, {page: @page, next: @result, current: @result})
    Sync =>
      try
        html = @page.get.sync null, 'content'
        @channel.sendToQueue config.listsHtmlQueue, new Buffer(html, 'utf8'),
          headers:
            parser: 'i-tender/list'
            etp: @etp
        result = @page.evaluate.sync null, ->
          next = $($('.pager span').filter(->
            $(@).text().indexOf('Страниц') is -1
          )[0]).next().text()
          next = parseInt(next) unless next is '>>'
          e = document.createEvent 'MouseEvents'
          e.initMouseEvent 'click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
          links = $(".pager span:not(:contains('Страницы:'))").next("a:not(:contains('<<'))")
          if links.length > 0
            nextLink = links[0]
          else nextLink = null
          if nextLink?
            nextLink.dispatchEvent e
            window.updating = true
            $("[id*='ctl00_ctl00_MainContent']").bind 'DOMNodeRemoved', ->
              if window.updating
                window.updating = false
                console.log 'UPDATED_NEW_DATA'
          next
        if result?
          @next = result
          @result = result
        else cb(null, {page: @page, next: null})
      catch e
        log.error e
        cb e