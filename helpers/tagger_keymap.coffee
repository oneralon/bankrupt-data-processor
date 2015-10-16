module.exports = keymap = [
    title: 'право аренды'
    keywords: [
      '(^| )право.{0,30} аренд'
    ]
  ,
    title: 'пассажирский транспорт'
    keywords: [
      '(^| )автобус'
      '(^| )минив(э|е)н'
      '(^| )микроавтобус'
      '(^| )пассажирск'
      ,
        word: '(^| )ЛИАЗ'
        ignorecase: no
      ,
        word: '(^| )ПАЗ'
        ignorecase: no
    ]
  ,
    title: 'автомобильная техника'
    keywords: [
      'прицеп'
      '(^| )цистерна'
      '(^| )купава'
      '(^| )оборудован.{0,25} для.{0,25} трактор'
      '(^| )оборудован.{0,25} для.{0,25} комбайн'
      '(^| )сеялка'
      '(^| )веялка'
      '(^| )культиватор'
    ]
  ,
    title: 'грузовые автомобили'
    keywords: [
      '(^| )грузово.{0,10}автомобиль'
      '(^| )тягач '
      '(^| )седельн'
      '(^| )фура'
      '(^| )кунг'
      '(^| )Камаз($| |\.|\,|\:|\-)'
      ,
        word: '(^| )КАМАЗ'
        ignorecase: no
      ,
        word: '(^| )МАЗ'
        ignorecase: no
      ,
        word: '(^| )MAN'
        ignorecase: no
      ,
        word: '(^| )МАН'
        ignorecase: no
      ,
        word: '(^| )ЗИЛ'
        ignorecase: no
      ,
        word: '(^| )ЗиЛ'
        ignorecase: no
      ,
        word: '(^| )УРАЛ'
        ignorecase: no
      ,
        word: '(^| )ГАЗ'
        ignorecase: no
    ]
  ,
    title: 'гаражи'
    keywords: [
      '(^| )гараж'
      '(^| )гаражн'
      '(^| )машиномест'
    ]
  ,
    title: 'животные,скот'
    keywords: [
      '(^| )КРС'
      '(^| )скот'
      '(^| )крупнорогат'
      '(^| )телка'
      '(^| )стельн'
      '(^| )ялова'
      '(^| )молодняк'
    ]
  ,
    title: 'жилая недвижимость'
    keywords: [
      '(^| )квартир'
      '(^| )дом($| )'
      '(^| )((?!не).{2}|^.{0,1})жил(ой|ая)'
      '(^| )лофт'
      '(^| )студи'
      '(^| )апартамент'
      '(^| )дачн'
      '((?!не).{2}|^.{0,1})жило.{0,25} здани'
      '((?!не).{2}|^.{0,1})жило.{0,25} строен'
      '(^| )домовладен'
    ]
  ,
    title: 'задолженность'
    keywords: [
      and: [
        '(^| )требовани(я|е)(?=([хми]*))\\3((?! к заявк).{8}|.{0,7}$)'
        '(^| )требовани(я|е)(?=([хми]*))\\3((?! к документ).{11}|.{0,10}$)'
        '(^| )требовани(я|е)(?=([хми]*))\\3((?! к допуск).{9}|.{0,8}$)'
      ]
      '(^| )долг((?!осрочн).{6}|.{0,5}$)'
      '(^| )задолженность'
      '(^| )дебиторск'
    ]
    alone: yes
  ,
    title: 'залог,обременение'
    keywords: [
      and: [
        '((?!не ).{3}|^.{0,2})залог'
        '((?!не явля[ею]тся предметом ).{22}|^.{0,21})залог'
        '((?!свободн(ая|ое|ые|ый) от ).{13}|^.{0,12})залог'
        '((?!не обремен[её]н ).{13}|^.{0,12})залог'
      ]
    ]
  ,
    title: 'земля,землеотвод'
    keywords: [
      '(^| )земельн'
      '(^| )землеотвод'
      '(^| )кадастр'
      '(^| )участок'
    ]
  ,
    title: 'инфраструктура'
    keywords: [
      '(^| )отопительн.{0,10}сет(ь|и)'
      '(^| )канализац.{0,10}сет(ь|и)'
      '(^| )водоснабжен.{0,10}сет(ь|и)'
      '(^| )сет(ь|и).{0,10}водоснабжен'
      '(^| )электропередач'
      '(^| )газоснабжен'
      '(^| )коллектор'
      '(^| )водопроводн'
      '(^| )электроснабжен'
      '(^| )теплопередач'
      '(^| )подстанц'
      '(^| )трансформаторная'
      '(^| )подъездн'
      '(^| )путепровод'
      '(^| )котельн'
      '(^| )водосброс'
      '(^| )дренаж'
      '(^| )плотин'
      '(^| )автодорог(а)'
      '(^| )кабельн.{0,20}эстакад(а|ы)'
      '(^| )автодорог(а|и)'
      ,
        word: '(^| )ЛЭП'
        ignorecase: no
    ]
  ,
    title: 'коммерческая недвижимость'
    keywords: [
      '(^| )столова'
      '(^| )каф(е|э)'
        and: [
          '(^| )бар'
          '^((?! БАР[\)\.,:]).{5}|^.{0,4})$'
        ]
        ignorecase: no
      '(^| )клуб($| )'
      '(^| )дискотек'
      '(^| )ресторан'
      '(^| )закусочн'
      '(^| )рюмочн'
      '(^| )шаурм'
      '(^| )шаверм'
      '(^| )шашлычна'
      '(^| )магазин'
      '(^| )супермаркет'
      '(^| )мини(\-)?маркет'
      '(^| )магазин'
      '(^| )розничн.*точка'
      '(^| )оптово-розничн'
      '(^| )торгово-закупочн'
      '(^| )автостоянк'
      '(^| )парковк'
      '(^| )унив(и|е)рмаг'
      '(^| )гостиниц'
    ]
  ,
    title: 'компьютеры,оргтехника'
    keywords: [
      '(^| )компьютер'
      '(^| )принтер'
      '(^| )сканер'
      '(^| )ксерокс'
      '(^| )копир'
      '(^| )мфу'
      '(^| )плот(т)?ер'
      '(^| )копир'
      '(^| )ноутбук'
      '(^| )планшет'
      '(^| )сервер'
      '(^| )image.{0,15}scan(n)?er'
    ]
  ,
    title: 'легковые и коммерческие авто'
    keywords: [
      '((?!грузовой).{8}|^.{0,7})(^| )авт(а|о)мобиль'
      '(^| )легк(а|о)вой авт(а|о)мобиль'
      '(^| )авт\. '
      '(^| )пикап'
      '(^| )джип'
      '(^| )седан'
      '(^| )х(е|э)тчб(е|э)к'
      '(^| )пирожок'
      '(^| )Порше'
      '(^| )Porsche'
      '(^| )ВАЗ'
      '(^| )Газель'
      '(^| )Соболь'
      '(^| )Т(а|о)йота'
      '(^| )Toyota'
      '(^| )Hundai'
      '(^| )Х(ю|у)ндай'
      '(^| )Х(ё|е)нд(е|э)'
      '(^| )Mazda'
      '(^| )Мазда'
      '(^| )Фиат'
      '(^| )FIAT'
      '(^| )Nissan'
      '(^| )Нис(с)?ан'
      ,
        word: '(^| )ГАЗ.{0,10}2752'
        ignorecase: no
      ,
        word: '(^| )УАЗ'
        ignorecase: no
    ]
  ,
    title: 'машины и оборудование'
    keywords: [
      '(^| )сборочн.* линия'
      '(^| )конвейер'
      '(^| )к(о|а)нвеер'
      '(^| )агрегат'
      '(^| )к(о|а)мпрес(с?)ор'
      '(^| )ст(е|э)нд($| )'
      '(^| )кран\-балк'
      '(^| )таль($| )'
      '(^| )генераторн'
      '(^| )генератор($| )'
      '(^| )кран.{0,10}консольн'
      '(^| )сварочн'
    ]
  ,
    title: 'мебель'
    keywords: [
      '(^| )стол(ы)?($| )'
      '(^| )стул(ья)?($| )'
      '(^| )платяной.{0,10} шкаф'
      '(^| )стеллаж'
      '(^| )тумб'
      '(^| )кровать'
      '(^| )прикроватн'
      '(^| )д/одежды'
      '(^| )для одежды'
      '(^| )комод'
      '(^| )сервант'
      '(^| )директорск'
      '(^| )кресл(о|а)'
      '(^| )полка(и)?.{0,10}для'
      '(^| )набор.{0,10}мебели'
      '(^| )мебельн.{0,10}гарнитур'
    ]
  ,
    title: 'офис'
    keywords: [
      '(^| )контор'
      '(^| )оф(ф)?ис(?!сервис)'
      '(^| )административн'
      '(^| )здани.{0,10}правлени(е|я)($| )'
    ]
  ,
    title: 'производственные здания,сооружения'
    keywords: [
      '(^| )цех($| |\.|\,)'
      '(^| )пристрой'
      '(^| )построй'
      '(^| )проходн'
      '(^| )корпус($| )'
      '(^| )промышлен'
      '(^| )депо'
      '(^| )фабрик'
      '(^| )инкубатор'
      '(^| )нежил.{0,10}здани'
      '(^| )коровник'
      '(^| )свиноферм'
      '(^| )птицеферм'
      '(^| )кузниц'
      '(^| )производствен.{0,10}строен'
      '(^| )мастерска'
      '(^| |\-)здани.{0,25}нежило'
    ]
  ,
    title: 'радиотехника'
    keywords: [
      '(^| )аудио'
      '(^| )микшер'
      '(^| )усилитель'
      '(^| )студийн'
    ]
  ,
    title: 'склад'
    keywords: [
      '(^| )склад'
      '(^| )логисти'
      '(^| )хранилищ'
      '(^| )кладов'
      '(^| )ангар($| )'
    ]
  ,
    title: 'специальная автотехника'
    keywords: [
      '(^| )вездеход'
      '(^| )самосвал'
      '(^| )грейдер'
      '(^| )каток'
      '(^| )автокран'
      '(^| )траншее'
      '(^| )канаво'
      '(^| )укладчик'
      '(^| )погрузчик'
      '(^| )электрокар'
      '((?!оборудовани[ея] для ).{17}|^.{0,16})трактор'
      '(^| )бульдозер'
      '(^| )комбайн'
      '(^| )экск(а|о)ватор'
      '(^| )кормоуборочн'
      '(^| )топливозаправщик'
      '(^| )мусоровоз'
      '(^| )ассенизац.{0,15}машин'
      '(^| )машина.{0,15}коммунальная'
      '(^| )Komatsu'
      '(^| )Кома(т)?цу'
      '(^| )Беларус(ь)?'
      '(^| )Bobcat'
      '(^| )Бобк(а|э|е)т'
    ]
  ,
    title: 'средства связи'
    keywords: [
      and: [
        '((?!по).{2}|^.{0,1})(^| )телефон'
        '(^| )телефон((?! для справ).{10}|.{0,9}$)'
        '(^| )телефон((?! для предв).{10}|.{0,9}$)'
      ]
      '(^| )спутник'
      '(^| )сотов'
      '(^| )рация'
      '(^| )передатчик'
      '(^| )антенн'
      ,
        word: '(^| )АТС'
        ignorecase: no
    ]
  ,
    title: 'станки'
    keywords: [
      '(^| )стан(ки|ок)'
      '(^| )токарн'
      '(^| )расточн'
      '(^| )координатн'
      '(^| )фрезерн'
      '(^| )штамповочн'
      '(^| )кузнечн'
      '(^| )стан(о?)к(и?)'
      '(^| )обрабатывающ'
      '(^| )ЧПУ'
      '(^| )робото'
      '(^| )автомат($| )'
      '(^| )прессовочн'
      '(^| )формовочн'
      '(^| )штамп'
      '(^| )электромеханическ'
      '(^| )электрогидравлическ'
      '(^| )пневматическ'
      '(^| )пневмогидравлическ'
      '(^| )шлифовальн'
      '(^| )пресс'
    ]
  ,
    title: 'юридические сложности'
    keywords: [
      '(?!госрегистрац.{0,30})(^| )собственник'
      '(^| )титул'
      '(?!свидетельств.{0,20})(^| )собственност'
      '(^| )документ.{0,10}отсутству(е|ю)т'
    ]
]