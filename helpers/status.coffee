module.exports = (status) ->
  status = status.trim()
  for key, val of statuses
    for regexp in val
      if regexp.test status then return key
  return status

module.exports.statuses = statuses =
  'Извещение опубликовано': [
    /^Извещение опубликовано$/i
    /^Новая$/i
    /^Опубликован\(\-а\)$/i
    /^Опубликована$/i
    /^Опубликован\(\-а\)$/i
    /^Объявленные торги$/i
    /^объявлены$/i
    /^Ожидает публикации$/i
    /^Торги объявлены$/i
    /^Подготовка заявки$/i
    /^Заявка сформирована$/i
    /^Заявка зарегистрирована$/i
    /^Торги объявлены$/i
    /^Ожидает подписи извещения$/i
  ]
  'Прием заявок': [
    /^Допущена$/i
    /^При(ё|е)м заявок$/i
    /^Торги в стадии при(е|ё)ма заявок$/i
    /^ид(е|ё)т при(е|ё)м заявок$/i
    /^Начало при(е|ё)ма заявок$/i
    /^Подача предложени(е|я|й) о цене$/i
    /^ид(е|ё)т при(е|ё)м заявок \(приостановленны\)$/i
  ]
  'Прием заявок завершен': [
    /^Определение участников торгов$/i
    /^При(е|ё)м заявок на интервале не активен$/i
    /^Период заверш(е|ё)н$/i
    /^Рассмотрение заявок$/i
    /^Торги с заверш(е|ё)нным при(е|ё)мом заявок$/i
    /^Определение участников$/i
    /^При(е|ё)м заявок заверш(е|ё)н$/i
    /^Закончен при(е|ё)м заявок$/i
    /^Проверка заявок$/i
    /^Окончена проверка заявок$/i
    /^Подписан протокол о подведении итогов при(е|ё)ма и регистрации заявок$/i
    /^При(ё|е)м заявок окончен$/i
    /^при(ё|е)м заявок заверш(ё|е)н \(приостановленны\)$/i
  ]
  'Идут торги': [
    /^Идут торги$/i
    /^Подведение результатов$/i
    /^Подведение итогов$/i
    /^Торги в стадии проведения$/i
    /^Подача ценовых предложений завершена$/i
    /^Торги в стадии подведения итогов$/i
    /^в стадии проведения$/i
    /^подводятся итоги$/i
    /^подведение результатов торгов$/i
    /^Ид(е|ё)т подведение итогов$/i
    /^Торги проводятся$/i
    /^На рассмотрении$/i
    /^Торги идут$/i
    /^подводятся итоги \(приостановленны\)$/i
    /^Участники торгов определены$/i
  ]
  'Торги завершены': [
    /^Окончен$/i
    /^Заверш(е|ё)н(\(\-а\))?$/i
    /^Торги завершены$/i
    /^торги завершены$/i
    /^Оконченный$/i
    /^Заверш(е|ё)нные$/i
    /^Торги завершены$/i
    /^Подписан договор$/i
    /^торги завершены \(приостановленны\)$/i
  ]
  'Торги отменены': [
    /^Отмен(е|ё)н организатором$/i
    /^Отмен(е|ё)н(\(\-а\))?$/i
    /^торги отменены$/i
    /^Торги отменены$/i
    /^Торги удалены$/i
    /^Торги по лоту отменены$/i
  ]
  'Торги не состоялись': [
    /^Не состоялся$/i
    /^Не состоялся\(\-ась\)$/i
    /^Торги не состоялись$/i
  ]
  'Торги приостановлены': [
    /^Приостановлен$/i
    /^Торги приостановлены$/i
    /^Приостановлен(\(\-а\))?$/i
    /^При(е|ё)м заявок приостановлен$/i
    /^Торги по лоту приостановлены$/i
  ]