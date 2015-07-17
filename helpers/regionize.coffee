_         = require 'lodash'

module.exports = (region) ->
  replaced = {}
  console.log region
  if _.isEmpty(region) or /null/i.test(region) or /не определен/i.test region
    return 'Не определен'
  replaced.country = /(край.*?)($|\s)/ig.exec(region)
  region = region.replace /(край.*?)($|\s)/ig, ''

  replaced.area = /(обл.*?)($|\s)/ig.exec(region)
  region = region.replace /(обл.*?)($|\s)/ig, ''

  replaced.city = /(?:\s|^)(г.*?)($|\s)/ig.exec(region)
  region = region.replace /(?:\s|^)(г.*?)($|\s)/ig, ''

  replaced.round = /(авт.*?окр)($|\s)/ig.exec(region)
  region = region.replace /(авт.*?окр)($|\s)/ig, ''

  replaced.republic = /(респ.*?)($|\s)/ig.exec(region)
  region = region.replace /(респ.*?)($|\s)/ig, ''

  region = region.toLowerCase().split(/\s| /).map((item) ->
    item = item.charAt(0).toUpperCase() + item.slice(1)
    item
  ).join(' ')

  for k,v of replaced
    if v?
      if k is 'country'
        region = region + ' край'
      if k is 'area'
        region = region + ' область'
      if k is 'city'
        region = 'город ' + region
      if k is 'republic'
        region = region + ' республика'

  region = region.replace /\//g, ''
  region = region.replace /\(.*?\)/g, ''

  region = region.replace /\s\s/g, ' '
  region = region.replace /(\s|^)ао(\s|$)/ig, ' '

  region = region.trim()
  region