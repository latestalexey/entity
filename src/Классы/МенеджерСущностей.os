#Использовать "../internal"

#Использовать asserts
#Использовать logos
#Использовать reflector

// Хранит данные о типах полей, колонках, настроек таблиц для типов сущностей
Перем МодельДанных;

// Хранит коннектор к БД, транслирующий команды менеджера сущностей в запросы к БД
Перем Коннектор;
Перем СтрокаСоединенияКоннектора;
Перем ПараметрыКоннектора;

Перем Лог;

// Конструктор объекта МенеджерСущностей.
//
// Параметры:
//   ТипКоннектора - Тип - Тип класса, реализующего интерфейс Коннектор.
//   СтрокаСоединения - Строка - Строка соединения к БД, к которой подключается коннектор.
//   ППараметрыКоннектора - Массив - Массив дополнительных параметров коннектора. Содержимое произвольное.
//
Процедура ПриСозданииОбъекта(Знач ТипКоннектора, Знач СтрокаСоединения = "", Знач ППараметрыКоннектора = Неопределено)
	Лог = Логирование.ПолучитьЛог("oscript.lib.entity.manager");
	Лог.Отладка("Инициализация менеджера сущностей с коннектором %1", ТипКоннектора);
	ПроверитьПоддержкуИнтерфейсаКоннектора(ТипКоннектора);

	МодельДанных = Новый МодельДанных;

	Коннектор = РаботаСКоннекторами.СоздатьКоннектор(ТипКоннектора);

	СтрокаСоединенияКоннектора = СтрокаСоединения;
	Если ППараметрыКоннектора = Неопределено Тогда
		ПараметрыКоннектора = Новый Массив;
	Иначе
		ПараметрыКоннектора = ППараметрыКоннектора;
	КонецЕсли;
КонецПроцедуры

// Регистрирует переданный тип класса-сценария в модели данных.
//
// Параметры:
//   ТипСущности - Тип - Тип для добавления в модель
//
Процедура ДобавитьКлассВМодель(ТипСущности) Экспорт
	ПроверитьЧтоКлассЯвляетсяСущностью(ТипСущности);

	МодельДанных.СоздатьОбъектМодели(ТипСущности);
КонецПроцедуры

// Запускает процессы инициализации коннектора и таблиц БД.
//
Процедура Инициализировать() Экспорт
	
	РаботаСКоннекторами.ОткрытьКоннектор(Коннектор, СтрокаСоединенияКоннектора, ПараметрыКоннектора);

	ОбъектыМодели = МодельДанных.ПолучитьОбъектыМодели();
	
	Для Каждого ОбъектМодели Из ОбъектыМодели Цикл
		Коннектор.ИнициализироватьТаблицу(ОбъектМодели);
		
		ПодчиненныеТаблицы = ОбъектМодели.ПодчиненныеТаблицы();
		Для Каждого ПодчиненнаяТаблица Из ПодчиненныеТаблицы Цикл
			
			ОбъектМоделиЭлементКоллекции = ОбработкаКоллекций.ПолучитьОбъектМоделиДляПодчиненнойТаблицы(
				ОбъектМодели, 
				ПодчиненнаяТаблица
			);
			
			Коннектор.ИнициализироватьТаблицу(ОбъектМоделиЭлементКоллекции);
		КонецЦикла;
	КонецЦикла;

КонецПроцедуры

// Сохраняет сущность в БД.
//
// Параметры:
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для сохранения в БД.
//
Процедура Сохранить(Сущность) Экспорт
	ТипСущности = ТипЗнч(Сущность);
	ОбъектМодели = МодельДанных.Получить(ТипСущности);
	ПулСущностей = ПолучитьПулСущностей(ТипСущности);
	РаботаСКоннекторами.Сохранить(Коннектор, ОбъектМодели, ПулСущностей, Сущность);
КонецПроцедуры

// Осуществляет поиск сущностей переданного типа по идентификатору.
//
// Параметры:
//   ТипСущности - Тип - Тип искомой сущности.
//   Отбор - Произвольный - Отбор для поиска.
//     Если параметр не задан или равен "Неопределено", то возвращаются все найденные сущности указанного типа.
//     Если параметр имеет тип "Соответствие", то каждое значение соответствия преобразуется к условию поиска
//      ИмяПоля = ЗначениеПоля, где ИмяПоля - ключ элемента соответствия, ЗначениеПоля - значение элемента соответствия.
//     Если параметр имеет тип "Массив", то каждое элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена полей.
//     Если параметр имеет тип "ЭлементОтбора", то элемент отбора преобразуется к условию поиска.
//       В качестве "ПутьКДанным" указываются имена полей.
//
//  Возвращаемое значение:
//   Массив - Массив найденных сущностей. В качестве элементов массива выступают
//     экземпляры класса с типом, равным переданному "ТипуСущности", с заполненными значениями полей.
//
Функция Получить(ТипСущности, Отбор = Неопределено) Экспорт
	ОбъектМодели = МодельДанных.Получить(ТипСущности);
	ПулСущностей = ПолучитьПулСущностей(ТипСущности);
	Возврат РаботаСКоннекторами.Получить(Коннектор, ОбъектМодели, ПулСущностей, Отбор);
КонецФункции

// Осуществляет поиск сущности переданного типа по идентификатору.
//
// Параметры:
//   ТипСущности - Тип - Тип искомой сущности.
//   Отбор - Произвольный - Отбор для поиска.
//     Если параметр не задан или равен "Неопределено", то возвращаются все найденные сущности указанного типа.
//     Если параметр имеет тип "Соответствие", то каждое значение соответствия преобразуется к условию поиска.
//      ИмяПоля = ЗначениеПоля, где ИмяПоля - ключ элемента соответствия, ЗначениеПоля - значение элемента соответствия.
//     Если параметр имеет тип "Массив", то каждое элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена полей.
//     Если параметр имеет тип "ЭлементОтбора", то элемент отбора преобразуется к условию поиска.
//       В качестве "ПутьКДанным" указываются имена полей.
//     Любой другой тип интерпретируется как поиск по &Идентификатору.
//
//  Возвращаемое значение:
//   Произвольный - Если сущность была найдена, то возвращается экземпляр класса с типом, равным переданному
//     "ТипуСущности", с заполненными значениями полей. Иначе возвращается "Неопределено".
//
Функция ПолучитьОдно(ТипСущности, Знач Отбор = Неопределено) Экспорт
	ОбъектМодели = МодельДанных.Получить(ТипСущности);
	ПулСущностей = ПолучитьПулСущностей(ТипСущности);
	Возврат РаботаСКоннекторами.ПолучитьОдно(Коннектор, ОбъектМодели, ПулСущностей, Отбор);
КонецФункции

// Выполняет удаление сущности из базы данных.
// Сущность должна иметь заполненный идентификатор.
//
// Параметры:
//   Сущность - Произвольный - Удаляемая сущность
//
Процедура Удалить(Сущность) Экспорт
	ТипСущности = ТипЗнч(Сущность);
	ОбъектМодели = МодельДанных.Получить(ТипСущности);
	ПулСущностей = ПолучитьПулСущностей(ТипСущности);
	РаботаСКоннекторами.Удалить(Коннектор, ОбъектМодели, ПулСущностей, Сущность);
КонецПроцедуры

// Выполняет очистку полную данных библиотеки.
// Дополнительно посылает всем используемым коннекторам запросы на закрытие соединения.
//
Процедура Закрыть() Экспорт
	РаботаСКоннекторами.ЗакрытьКоннектор(Коннектор);
	МодельДанных.Очистить();
	СвойстваКоннектора = РаботаСКоннекторами.ПолучитьСвойстваКоннектора(Коннектор);
	ХранилищаСущностей.Закрыть(ТипЗнч(Коннектор), СвойстваКоннектора.СтрокаСоединения, СвойстваКоннектора.Параметры);
	// Для освобожения ссылок на все коннекторы и соединения с СУБД
	ВыполнитьСборкуМусора();
КонецПроцедуры

// Посылает коннектору запрос на начало транзакции.
//
Процедура НачатьТранзакцию() Экспорт
	РаботаСКоннекторами.НачатьТранзакцию(Коннектор);
КонецПроцедуры

// Посылает коннектору запрос на фиксацию транзакции.
//
Процедура ЗафиксироватьТранзакцию() Экспорт
	РаботаСКоннекторами.ЗафиксироватьТранзакцию(Коннектор);
КонецПроцедуры

// Посылает коннектору запрос на отмену транзакции.
//
Процедура ОтменитьТранзакцию() Экспорт
	РаботаСКоннекторами.ОтменитьТранзакцию(Коннектор);
КонецПроцедуры

// Возвращает текущий активный коннектор.
//
//  Возвращаемое значение:
//   АбстрактныйКоннектор - Возвращает экземпляр коннектора. Конкретная реализация определяется параметром
//      ТипКоннектора при вызове конструктора МенеджерСущностей.
//
Функция ПолучитьКоннектор() Экспорт
	Возврат Коннектор;
КонецФункции

// Получает ХранилищеСущностей, привязанное к переданному типу сущности.
//
// Параметры:
//   ТипСущности - Тип - Тип сущности, зарегистрированный в Модели
//
//  Возвращаемое значение:
//   ХранилищеСущностей - Хранилище сущностей, привязанное к переданному типу сущности.
//
Функция ПолучитьХранилищеСущностей(ТипСущности) Экспорт
	ОбъектМодели = МодельДанных.Получить(ТипСущности);
	ХранилищеСущностей = ХранилищаСущностей.Получить(
		ОбъектМодели,
		Коннектор
	);
	Возврат ХранилищеСущностей;
КонецФункции

// @internal
// Для служебного пользования.
//
// Возвращает пул сущностей из хранилища сущностей, привязанного к переданному типу сущности.
//
// Параметры:
//   ТипСущности - Тип - Тип сущности, зарегистрированный в Модели.
//
//  Возвращаемое значение:
//   Соответствие - Пул сущностей.
//
Функция ПолучитьПулСущностей(ТипСущности) Экспорт
	Возврат ПолучитьХранилищеСущностей(ТипСущности).ПолучитьПулСущностей();
КонецФункции

// <Описание процедуры>
//
// Параметры:
//   ТипКоннектора - Тип - Тип, проверяемый на реализацию интерфейса
//
Процедура ПроверитьПоддержкуИнтерфейсаКоннектора(ТипКоннектора)

	ИнтерфейсКоннектор = Новый ИнтерфейсОбъекта;
	ИнтерфейсКоннектор.ИзОбъекта(Тип("АбстрактныйКоннектор"));

	РефлекторОбъекта = Новый РефлекторОбъекта(ТипКоннектора);
	ПоддерживаетсяИнтерфейсКоннектора = РефлекторОбъекта.РеализуетИнтерфейс(ИнтерфейсКоннектор);

	Ожидаем.Что(
		ПоддерживаетсяИнтерфейсКоннектора,
		СтрШаблон("Тип <%1> не реализует интерфейс коннектора", ТипКоннектора)
	).ЭтоИстина();

КонецПроцедуры

// <Описание процедуры>
//
// Параметры:
//   ТипКласса - Тип - Тип, в котором проверяется наличие необходимых аннотаций.
//
Процедура ПроверитьЧтоКлассЯвляетсяСущностью(ТипКласса)

	РефлекторОбъекта = Новый РефлекторОбъекта(ТипКласса);
	ТаблицаМетодов = РефлекторОбъекта.ПолучитьТаблицуМетодов("Сущность", Ложь);
	Ожидаем.Что(ТаблицаМетодов, СтрШаблон("Класс %1 не имеет аннотации &Сущность", ТипКласса)).ИмеетДлину(1);

	ТаблицаСвойств = РефлекторОбъекта.ПолучитьТаблицуСвойств("Идентификатор");
	Ожидаем.Что(ТаблицаСвойств, СтрШаблон("Класс %1 не имеет поля с аннотацией &Идентификатор", ТипКласса)).ИмеетДлину(1);

КонецПроцедуры