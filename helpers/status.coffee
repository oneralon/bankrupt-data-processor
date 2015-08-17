module.exports = (status) ->
  status = status.trim()
  statuses =
    'Извещение опубликовано': [

    ]
    'Прием заявок': [

    ]
  for key, val of statuses
    if val.indexOf status isnt -1 then return key
  return 'Не определен'