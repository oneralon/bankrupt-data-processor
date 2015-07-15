phantom   = require 'node-phantom-simple'
amqp      = require 'amqplib'
Sync      = require 'sync'

log       = require('./../helpers/logger')()
config    = require './../config'
queue     = config.listsQueue

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
  init: (cb) ->
    amqp.connect(config.amqpUrl).catch(cb).then (connection) =>
      connection.createChannel().catch(cb).then (channel) =>
        channel.assertQueue(queue)
        Sync =>
          ph = phantom.create.sync @
          page = ph.createPage.sync @
          cb null,
            connection: connection
            phantom: ph
            channel: channel
            page: page

  close: (cb) ->
    @page.close () =>
      @phantom.exit()
      @channel.close().catch(cb).then () =>
        @connection.close().catch(cb).then () =>
          cb()

  collect: (urls, cb) ->
    log.info "Start collecting from #{urls.length} sources"
    Sync =>
      inject @, @init.sync(@)
      for url, name of urls
        inject @, @proceed.sync @, url
      @close.sync(@)
      log.info 'Collecting completed'
      cb()

  proceed: (url, cb) ->
    log.info "Start collect #{url}"
    @url = url
    @current = 1
    @interval = setInterval =>
      log.error "Timeout on #{url}"
      clearInterval @interval
      cb()
    , config.timeout
    @page.open @url, (status) =>
      Sync =>
        inject @, @nextPage.sync(@)
        while @next isnt null
          inject @, @nextPage.sync(@)
        log.info "Complete collect #{url}"
        clearInterval @interval
        cb()

  nextPage: (cb) ->
    log.info "Start page #{@current} of #{@url}"
    @page.onConsoleMessage = (message) =>
      if message is 'UPDATED_NEW_DATA'
        log.info "Complete page #{@current} of #{@url}"
        cb(null, {page: @page, next: @result, current: @result})
    Sync =>
      html = @page.get.sync null, 'content'
      @channel.sendToQueue queue, new Buffer(html), {headers: {url: @url}}
      result = @page.evaluate.sync null, ->
        next = $($('.pager span').filter(->
          $(@).text().indexOf('Страниц') is -1
        )[0]).next().text()
        next = parseInt(next)
        e = document.createEvent 'MouseEvents'
        e.initMouseEvent 'click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
        nextLink = $($('.pager span').filter( -> $(@).text().indexOf('Страниц') is -1)[0]).next()?[0]
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