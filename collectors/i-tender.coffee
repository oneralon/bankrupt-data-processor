phantom   = require 'node-phantom-simple'
etag      = require 'etag'
cheerio   = require 'cheerio'
Sync      = require 'sync'

amqp      = require '../helpers/amqp'
logger    = require '../helpers/logger'
redis     = require '../helpers/redis'
log       = logger  'I-TENDER LIST COLLECTOR'
config    = require '../config'

inject = (to, from)->
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
    log.info "Start collect #{etp.href}"
    @url = etp.href
    @etp = etp
    @current = 1
    @page.open @etp.href, (err, res) =>
      if err?
        log.error err
        cb e
      cb "Non 200 code page" unless res is 'success'
      Sync =>
        try
          inject @, @nextPage.sync(@)
          while @next isnt null
            inject @, @nextPage.sync(@)
          log.info "Complete collect #{etp.href}"
          cb()
        catch e
          log.error e
          @close -> cb e

  nextPage: (cb) ->
    log.info "Start page #{@current} of #{@url}"
    @page.onError = (err) -> log.error err
    @page.onConsoleMessage = (message) =>
      if message is 'UPDATED_NEW_DATA'
        log.info "Complete page #{@current} of #{@url}"
        cb(null, {page: @page, next: @result, current: @result})
    Sync =>
      try
        if @retry
          state = redis.get.sync null, @etp.href
          @retry = false
          if state?
            if state is 'complete'
              cb(null, {page: @page, next: null})
            else
              log.info 'Return to collect'
              @page.evaluate.sync null, "function(){document.aspnetForm.__CVIEWSTATE.value = '#{state}'}"
        data = @page.evaluate.sync null, """
          function() {
            var data = '';
            $("[id*='ctl00_ctl00_MainContent'] tr.gridRow").each(function() {
              data = data + $(this).html().replace(/\\n|\\s/gi, '');
            });
            return data;
          }"""
        nonstored = redis.check.sync(null, @url + etag(data))
        if nonstored
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
            $("[id*='ctl00_ctl00_MainContent']").bind 'DOMNodeInserted', ->
              if window.updating and $("[id*='ctl00_ctl00_MainContent'] tr.gridRow").length > 0
                window.updating = false
                setTimeout ->
                  console.log 'UPDATED_NEW_DATA'
                , 50
          state = document.aspnetForm.__CVIEWSTATE.value
          if next?
            return JSON.stringify {next: next, state: state}
          else return null
        if result?
          result = JSON.parse(result)
          if result.state? and result.state.length > 30 and result.next is '>>'
            state = redis.get.sync null, @etp.href
            if state isnt result.state
              redis.set.sync null, @etp.href, result.state
          @next = result.next
          @result = result.next
        if @next is null
          redis.set.sync null, @etp.href, 'complete'
          cb(null, {page: @page, next: null})
      catch e
        log.error e
        @close -> cb e

argv = require('optimist').argv
etp = {name: argv.name, href: argv.href, platform: argv.platform}
collector.collect etp, (err) ->
  if err?
    log.error err
    process.exit 1
  else
    process.exit 0