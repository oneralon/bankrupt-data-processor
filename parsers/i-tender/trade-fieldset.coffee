module.exports.info = [
    field: 'membership_type'
    type: String
    title: 'Форма торга по составу участников'
    params:
      lower_case: yes
  ,
    field: 'price_submission_type'
    type: String
    title: 'Форма представления предложений о цене'
    params:
      lower_case: yes
  ,
    field: 'title'
    type: String
    title: 'Наименование'
  ,
    field: 'additional'
    type: String
    title: 'Дополнительные сведения'
  ,
    field: 'win_procedure'
    type: String
    title: 'Порядок и критерии определения победителя торгов'
  ,
    field: 'submission_procedure'
    type: String
    title: 'Порядок представления заявок на участие в торгах'
  ,
    field: 'holding_date'
    type: Date
    title: 'Дата проведения'
  ,
    ###
      * Для аукциона
    ###
    field: 'requests_start_date'
    type: Date
    title: 'Дата начала представления заявок на участие'
  ,
    field: 'requests_end_date'
    type: Date
    title: 'Дата окончания представления заявок на участие'
  ,
    ###
      * Для торгов
    ###
    field: 'intervals_start_date'
    type: Date
    title: 'Дата начала первого интервала'
  ,
    field: 'interval_end_date'
    type: Date
    title: 'Дата окончания последнего интервала'
  ,
    field: 'official_publish_date'
    type: Date
    title: 'Дата публикации сообщения о проведении открытых торгов в официальном издании'
  ,
    field: 'print_publish_date'
    type: Date
    title: 'Дата публикации в печатном органе по месту нахождения должника'
  ,
    field: 'bankrot_date'
    type: Date
    title: 'Дата размещения сообщения в Едином федеральном реестре сведений о банкротстве'
  ,
    field: 'results_place'
    type: String
    title: 'Место'
  ,
    field: 'results_date'
    type: Date
    title: 'Дата'
  ,
    field: 'contract_signing_person'
    type: String
    title: 'Лицо, подписывающее договор'
]
module.exports.debtor = [
    field: 'debtor_type'
    type: String
    title: 'Тип должника'
  ,
    field: 'inn'
    type: String
    title: 'ИНН'
  ,
    field: 'short_name'
    type: String
    title: 'Сокращенное наименование'
  ,
    field: 'full_name'
    type: String
    title: 'Полное наименование'
  ,
    field: 'ogrn'
    type: String
    title: 'ОГРН'
  ,
    field: 'judgment'
    type: String
    title: 'Основание для проведения торгов (реквизиты судебного акта арбитражного суда)'
  ,
    field: 'reviewing_property'
    type: String
    title: 'Порядок ознакомления с имуществом'
  ,
    field: 'region'
    type: String
    title: 'Регион'
  ,
    field: 'arbitral_name'
    type: String
    title: 'Наименование арбитражного суда'
  ,
    field: 'bankruptcy_number'
    type: String
    title: 'Номер дела о банкротстве'
  ,
    field: 'arbitral_commissioner'
    type: String
    title: 'Арбитражный управляющий'
  ,
    field: 'arbitral_organization'
    type: String
    title: 'Наименование организации арбитражных управляющих'
  ,
    field: 'contract_procedure'
    type: String
    title: 'Порядок и срок заключения договора купли-продажи'
  ,
    field: 'payment_terms'
    type: String
    title: 'Сроки платежей, реквизиты счетов'
]
module.exports.owner = [
    field: 'short_name'
    type: String
    title: 'Сокращенное наименование'
  ,
    field: 'full_name'
    type: String
    title: 'Полное наименование'
  ,
    field: 'internet_address'
    type: String
    title: 'Адрес сайта'
  ,
    field: 'inn'
    type: String
    title: 'ИНН'
  ,
    field: 'kpp'
    type: String
    title: 'КПП'
  ,
    field: 'ogrn'
    type: String
    title: 'ОГРН'
  ,
    field: 'ogrnip'
    type: String
    title: 'ОГРНИП'
]
module.exports.contact = [
    field: 'name'
    type: String
    title: 'Ф.И.О.'
  ,
    field: 'phone'
    type: String
    title: 'Телефон'
  ,
    field: 'fax'
    type: String
    title: 'Факс'
  ,
]