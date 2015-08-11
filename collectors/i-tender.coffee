phantom   = require 'node-phantom-simple'
Sync      = require 'sync'

amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
log       = logger  'I-TENDER LIST COLLECTOR'
config    = require '../config'

inject    = (to, from)->
  for key, val of from
    to[key] = val

collector =
  phantom: null
  current: null
  next: null
  url: null
  page: null
  state: null
  retry: true
  interval: null
  cookies: null
  watchdog: null
  init: (cb) ->
    Sync =>
      try
        ph = phantom.create.sync @
        ph.onError = (err) ->
          log.info err
          cb err
        page = ph.createPage.sync @
        cb null,
          phantom: ph
          page: page
      catch e
        log.error e
        @close -> cb e

  close: (cb) ->
    clearInterval @watchdog
    @phantom.exit()
    cb()

  collect: (etp, cb) ->
    Sync =>
      try
        inject @, @init.sync(@)
        @watchdog = setInterval =>
          if @phantom.exitCode isnt null
            @close -> cb 'Killed phantom'
        , 120000
        inject @, @proceed.sync @, etp
        @close.sync(@)
        log.info 'Collecting completed'
        cb()
      catch e
        log.error e
        @close -> cb e

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
          @close -> cb e

  nextPage: (cb) ->
    log.info "Start page #{@current} of #{@url}"
    @page.onConsoleMessage = (message) =>
      if message is 'UPDATED_NEW_DATA'
        log.info "Complete page #{@current} of #{@url}"
        cb(null, {page: @page, next: @result, current: @result})
    Sync =>
      try
        if @retry
          state = redis.get.sync null, @etp.url
          @retry = false
          if state?
            if state is 'complete'
              cb(null, {page: @page, next: null})
            else
              log.info 'Return to collect'
              @page.evaluate.sync null, "function(){document.aspnetForm.__CVIEWSTATE.value = '#{state}'}"
        html = @page.get.sync null, 'content'
        amqp.publish.sync null, config.listsHtmlQueue, new Buffer(html, 'utf8'),
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
          state = document.aspnetForm.__CVIEWSTATE.value
          if next?
            return JSON.stringify {next: next, state: state}
          else return null
        if result?
          result = JSON.parse(result)
          if result.state? and result.state.length > 30
            state = redis.get.sync null, @etp.url
            if state isnt result.state
              redis.set.sync null, @etp.url, result.state
          @next = result.next
          @result = result.next
        else
          redis.set.sync null, @etp.url, 'complete'
          cb(null, {page: @page, next: null})
      catch e
        log.error e
        @close -> cb e

argv = require('optimist').argv
etp = {name: argv.name, url: argv.url, platform: argv.platform}
collector.collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0