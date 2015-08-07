module.exports.info = [
    field: 'number'
    type: Number
    title: 'Номер'
  ,
    field: 'title'
    type: String
    title: 'Наименование'
  ,
    field: 'status'
    type: String
    title: 'Статус'
  ,
    field: 'procedure'
    type: String
    title: 'Порядок оформления участия в торгах, перечень представляемых участниками торгов документов и требования к их оформлению'
  ,
    field: 'category'
    type: String
    title: 'Категория лота'
  ,
    field: 'currency'
    type: String
    title: 'Валюта цены по ОКВ'
  ,
    field: 'start_price'
    type: Number
    title: 'Начальная цена, руб.'
  ,
    field: 'information'
    type: String
    title: 'Сведения об имуществе должника, его составе, характеристиках, описание, порядок ознакомления'
  ,
    ###
      * Для аукциона
    ###
    field: 'step_percent'
    type: Number
    title: 'Шаг, % от начальной цены'
  ,
    field: 'step_sum'
    type: Number
    title: 'Шаг, руб.'
  ,
    ###
      * Для публичного предложения
    ###
    field: 'price_reduction_type'
    type: String
    title: 'Тип снижения цены публичного предложения'
  ,
    field: 'current_sum'
    type: Number
    title: 'Текущая цена, руб.'
  ,
    field: 'calc_method'
    type: String
    title: 'Способ расчета обеспечения'
  ,
    field: 'deposit_size'
    type: Number
    title: 'Размер задатка, руб.'
  ,
    field: 'deposit_payment_date'
    type: String
    title: 'Дата внесения задатка'
  ,
    field: 'deposit_return_date'
    type: String
    title: 'Дата возврата задатка'
  ,
    field: 'deposit_procedure'
    type: String
    title: 'Порядок внесения и возврата задатка'
  ,
    field: 'bank_name'
    type: String
    title: 'Название банка'
  ,
    field: 'payment_account'
    type: String
    title: 'Расчетный счет'
  ,
    field: 'correspondent_account'
    type: String
    title: 'Кор. счет'
  ,
    field: 'bik'
    type: String
    title: 'БИК'
]

module.exports.interval = [
    field: 'interval_start_date'
    type: Date
    title: 'Дата начала интервала'
  ,
    field: 'request_start_date'
    type: Date
    title: 'Дата начала приема заявок на интервале'
  ,
    field: 'request_end_date'
    type: Date
    title: 'Дата окончания приема заявок на интервале'
  ,
    field: 'interval_end_date'
    type: Date
    title: 'Дата окончания интервала'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение цены предыдущего интервала на процент от начальной цены, проценты'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение от предыдущей цены, проценты'
  ,
    field: 'price_reduction_percent'
    type: Number
    title: 'Снижение от предыдущей цены, рубли'
  ,
    field: 'deposit_sum'
    type: Number
    title: 'Задаток на интервале, руб.'
  ,
    field: 'interval_price'
    type: Number
    title: 'Цена на интервале, руб.'
  ,
    field: 'comment'
    type: String
    title: 'Комментарий'
]
