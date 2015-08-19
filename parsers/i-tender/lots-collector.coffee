Phantom   = require 'node-phantom-simple'
Sync      = require 'sync'
fs        = require 'fs'

jquery    = fs.readFileSync(__dirname + '/jquery.js').toString()

logger    = require '../../helpers/logger'
log       = logger  'I-TENDER LOTS URL COLLECTOR'

module.exports =
  phantom: null
  page: null
  cviewstate: null
  current: 1
  prev: 0
  next: 0
  url: null
  urls: []
  init: (cb) ->
    Sync =>
      try
        @phantom = Phantom.create.sync @
        @phantom.onError = (err) -> cb err
        @page = @phantom.createPage.sync @
        @page.onError = (err) -> log.error err
        while code isnt 'success'
          code = @page.open.sync @, @url
        cb()
      catch e then cb e
  close: (cb) ->
    @phantom.exit()
    cb()
  collect: (url, cb) ->
    @url = url
    Sync =>
      try
        @init.sync @
        while @next isnt ''
          @next = @proceed.sync @
        @close.sync @
        log.info "Complete collecting urls of #{@url}"
        cb null, @urls
      catch e then @close -> cb e
  proceed: (cb) ->
    log.info "Collect on page #{@current}"
    @page.onUrlChanged = (targetUrl) =>
      Sync =>
        try
          urls = @page.evaluate.sync null, ->
            urls = []
            lots = $("table[id*='ctl00_ctl00_MainContent_ContentPlaceHolderMiddle_ctl00_srLots'] tr:not([class='gridHeader'])")
            for lot in lots
              urls.push $(lot).find('td.gridAltColumn a').attr('href')
            JSON.stringify urls
          for url in JSON.parse(urls)
            if url? and @urls.indexOf(url) is -1 then @urls.push url
          next = @page.evaluate.sync null, ->
            links = $("table[id*='ctl00_ctl00_MainContent_ContentPlaceHolderMiddle_ctl00_srLots'] .pager span:not(:contains('Страницы:'))").next("a:not(:contains('<<'))")
            if links.length > 0 then return true
            else return null
          cb(null, next)
        catch e then @close -> cb e
    Sync =>
      try
        console.log jquery
        @page.evaluate.sync null, jquery
        result = @page.evaluate.sync null, ->
          links = $(".pager span:not(:contains('Страницы:'))").next("a:not(:contains('<<'))")
          if links.length > 0
            nextLink = links[0]
            e = document.createEvent 'MouseEvents'
            e.initMouseEvent 'click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
            window.updating = true
            next = $(nextLink).text()
            nextLink.dispatchEvent e
          state = document.aspnetForm.__CVIEWSTATE.value
          JSON.stringify {next: next, state: state}
        result = JSON.parse(result)
        @cviewstate = result.state
        @current = parseInt(result.next) or @prev + 2
        @prev = @current + 1
        @next = result.next
      catch e then @close -> cb e